package ${YYAndroidPackageName};

import android.app.AlertDialog;
import android.content.*;
import android.database.Cursor;
import android.net.Uri;
import android.os.CancellationSignal;
import android.os.ParcelFileDescriptor;
import android.provider.DocumentsContract;
import android.system.Os;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.text.DateFormat;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/** Optional shared-folder transport. Only the GML validator can authorize an import. */
final class SaveSyncAndroid {
    static final int PICK_FOLDER = 0x4D03;
    interface Events { void send(int ticket, String action, String detail, String names, int choice); }
    private final Context context;
    private final File root;
    private final SharedPreferences preferences;
    private final Events events;
    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private final AtomicBoolean busy = new AtomicBoolean();
    private final AtomicInteger generation = new AtomicInteger();
    private volatile CancellationSignal cancellation = new CancellationSignal();
    private volatile Pending pending;
    private final AtomicInteger activeWork = new AtomicInteger();

    private static final class Pending {
        final int ticket;
        final Uri tree;
        final File state;
        final Map<String, byte[]> local, live;
        final List<SaveSyncFiles.Snapshot> heads;
        final SaveSyncFiles.Snapshot chosen;
        final boolean resolved;
        boolean applied;
        Pending(int ticket, Uri tree, File state, Map<String, byte[]> local, Map<String, byte[]> live,
                List<SaveSyncFiles.Snapshot> heads, SaveSyncFiles.Snapshot chosen, boolean resolved) {
            this.ticket = ticket; this.tree = tree; this.state = state; this.local = local; this.live = live;
            this.heads = heads; this.chosen = chosen; this.resolved = resolved;
        }
    }

    SaveSyncAndroid(Context context, Events events) {
        this.context = context.getApplicationContext(); this.root = context.getFilesDir(); this.events = events;
        preferences = context.getSharedPreferences("am2r_save_sync", Context.MODE_PRIVATE);
    }

    private volatile Map<String, String> captions = Collections.emptyMap();

    boolean setText(String json) {
        try {
            org.json.JSONObject values = new org.json.JSONObject(json);
            Map<String, String> next = new HashMap<>();
            Iterator<String> names = values.keys();
            while (names.hasNext()) {
                String name = names.next();
                Object value = values.get(name);
                if (!(value instanceof String)) return false;
                next.put(name, (String) value);
            }
            captions = Collections.unmodifiableMap(next);
            return true;
        } catch (org.json.JSONException invalid) { return false; }
    }

    private String text(String english) {
        String value = captions.get(english);
        return value == null ? english : value;
    }

    boolean configured() { return !preferences.getString("tree", "").isEmpty(); }
    boolean busy() { return busy.get() || activeWork.get() > 0; }

    boolean selectFolder() {
        if (busy() || RunnerActivity.CurrentActivity == null) return false;
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION | Intent.FLAG_GRANT_PREFIX_URI_PERMISSION);
        RunnerActivity.CurrentActivity.startActivityForResult(intent, PICK_FOLDER);
        return true;
    }

    void selected(int result, Intent data) {
        if (result != android.app.Activity.RESULT_OK || data == null || data.getData() == null) {
            events.send(0, "cancelled", "", "", -1); return;
        }
        try {
            int flags = data.getFlags() & (Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
            if (flags != (Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION))
                throw new IOException("Folder needs read and write access");
            context.getContentResolver().takePersistableUriPermission(data.getData(), flags);
            String previous = preferences.getString("tree", "");
            if (!preferences.edit().putString("tree", data.getData().toString()).commit())
                throw new IOException("Cannot remember sync folder");
            pending = null;
            if (!previous.isEmpty() && !previous.equals(data.getData().toString())) release(Uri.parse(previous));
            events.send(0, "configured", "Automatic sync is on.", "", -1);
        } catch (Exception error) { events.send(0, "error", "Could not keep access to that folder.", "", -1); }
    }

    boolean disable() {
        if (busy()) return false;
        String tree = preferences.getString("tree", "");
        if (!preferences.edit().remove("tree").commit()) return false;
        if (!tree.isEmpty()) release(Uri.parse(tree));
        pending = null; return true;
    }

    private void release(Uri uri) {
        try { context.getContentResolver().releasePersistableUriPermission(uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION); }
        catch (Exception ignored) { }
    }

    private String writer() throws IOException {
        String token = preferences.getString("writer", "");
        if (!SaveSyncFiles.token(token)) {
            token = UUID.randomUUID().toString().replace("-", "");
            if (!preferences.edit().putString("writer", token).commit()) throw new IOException("Cannot remember sync identity");
        }
        return token;
    }

    // Capture immutable staged copies before background folder work begins.
    int check(boolean allowImport, boolean review) {
        if (!configured() || activeWork.get() > 0 || !busy.compareAndSet(false, true)) return 0;
        int ticket = generation.incrementAndGet(); cancellation = new CancellationSignal(); pending = null;
        try {
            Map<String, byte[]> local = localFiles("backupstage_", true);
            Map<String, byte[]> live = localFiles("", false);
            if (!local.keySet().equals(live.keySet())) throw new IOException("Export does not match live saves");
            Uri tree = Uri.parse(preferences.getString("tree", ""));
            File state = new File(root, "save-sync/" + SaveSyncFiles.hash(tree.toString().getBytes(StandardCharsets.UTF_8)));
            if (!state.isDirectory() && !state.mkdirs()) throw new IOException("Cannot prepare sync state");
            activeWork.incrementAndGet();
            worker.execute(() -> {
                try {
                    SaveSyncFiles.Snapshot base = saved(new File(state, "base.zip"));
                    SaveSyncFiles.Snapshot queued = saved(new File(state, "outgoing.zip"));
                    if (queued != null) base = queued;
                    List<SaveSyncFiles.Snapshot> shared = readShared(tree, queued);
                    SaveSyncFiles.Decision decision = SaveSyncFiles.plan(writer(), local, base, shared, allowImport);
                    ensureCurrent(ticket);
                    switch (decision.action) {
                        case SaveSyncFiles.PUBLISH:
                            publish(tree, state, decision.snapshot, ticket);
                            finish(ticket, "done", "Saved to sync folder."); break;
                        case SaveSyncFiles.UNCHANGED:
                            if (queued != null) publish(tree, state, queued, ticket);
                            if (decision.snapshot != null) write(new File(state, "base.zip"), SaveSyncFiles.encode(decision.snapshot));
                            finish(ticket, "done", "Saves are up to date."); break;
                        case SaveSyncFiles.DEFER:
                            finish(ticket, "deferred", "Shared progress will be checked at file selection."); break;
                        case SaveSyncFiles.IMPORT:
                            stage(new Pending(ticket, tree, state, local, live, decision.candidates, decision.snapshot, false)); break;
                        default:
                            pending = new Pending(ticket, tree, state, local, live, decision.candidates, null, true);
                            if (review && allowImport) choices(pending);
                            else finish(ticket, "conflict", "Different saves found. Review them in Data settings.");
                    }
                } catch (Exception error) { finish(ticket, "error", "Sync could not finish. Local saves are unchanged."); }
                finally { endWork(ticket); }
            });
            return ticket;
        } catch (Exception error) {
            busy.set(false); events.send(ticket, "error", "Could not prepare complete saves for sync.", "", -1); return ticket;
        }
    }

    private void choices(Pending selection) throws IOException {
        ensureCurrent(selection.ticket);
        RunnerActivity activity = RunnerActivity.CurrentActivity;
        if (activity == null) throw new IOException("Game menu unavailable");
        ArrayList<String> labels = new ArrayList<>(); labels.add(text("Keep this device's saves"));
        DateFormat dates = DateFormat.getDateTimeInstance(DateFormat.SHORT, DateFormat.SHORT);
        for (SaveSyncFiles.Snapshot candidate : selection.heads)
            labels.add(text("Shared save set: ") + dates.format(new Date(candidate.created)));
        events.send(selection.ticket, "review", "Choose which progress to keep.", "", -1);
        activity.runOnUiThread(() -> {
            if (selection.ticket != generation.get()) return;
            new AlertDialog.Builder(activity).setTitle(text("Choose which progress to keep"))
                .setItems(labels.toArray(new String[0]), (dialog, which) -> {
                    String message = which == 0 ? text("Use this device's complete save set?")
                            : text("Use the selected shared save set? Slots absent from it will stay on this device.");
                    new AlertDialog.Builder(activity).setTitle(text("Resolve save conflict"))
                        .setMessage(message + text(" Previous progress will be kept in AM2R-Sync-Recovery."))
                        .setPositiveButton(text("Use these saves"), (confirm, button) ->
                            events.send(selection.ticket, "choice", "", "", which))
                        .setNegativeButton(text("Cancel"), (confirm, button) -> finish(selection.ticket, "conflict", "Sync conflict left unchanged."))
                        .setOnCancelListener(confirm -> finish(selection.ticket, "conflict", "Sync conflict left unchanged.")).show();
                })
                .setNegativeButton(text("Later"), (dialog, which) -> finish(selection.ticket, "conflict", "Sync conflict left unchanged."))
                .setOnCancelListener(dialog -> finish(selection.ticket, "conflict", "Sync conflict left unchanged.")).show();
        });
    }

    boolean choose(int choice) {
        Pending selection = pending;
        if (!busy.get() || selection == null || selection.chosen != null || selection.ticket != generation.get()
                || choice < 0 || choice > selection.heads.size()) return false;
        pending = null;
        activeWork.incrementAndGet();
        worker.execute(() -> {
            try {
                ensureCurrent(selection.ticket);
                if (!SaveSyncFiles.same(localFiles("", false), selection.live)) throw new IOException("Local progress changed");
                // Keep the exact alternatives before acknowledging either branch as resolved.
                recovery(selection.tree, selection.local);
                for (SaveSyncFiles.Snapshot candidate : selection.heads) recovery(selection.tree, candidate.files);
                if (choice == 0) {
                    publish(selection.tree, selection.state, SaveSyncFiles.make(writer(), selection.local, selection.heads), selection.ticket);
                    finish(selection.ticket, "done", "This device's saves were selected.");
                } else stage(new Pending(selection.ticket, selection.tree, selection.state,
                        selection.local, selection.live, selection.heads, selection.heads.get(choice - 1), true));
            } catch (Exception error) { finish(selection.ticket, "error", "Conflict was not applied. Progress has been retained."); }
            finally { endWork(selection.ticket); }
        });
        return true;
    }

    private void stage(Pending value) throws Exception {
        ensureCurrent(value.ticket);
        recovery(value.tree, value.local);
        Map<String, byte[]> incoming = SaveSyncFiles.merge(value.local, value.chosen.files);
        for (String name : SaveSyncFiles.NAMES) {
            File stage = new File(root, "syncstage_" + name);
            if (incoming.containsKey(name)) write(stage, incoming.get(name));
            else if (stage.exists() && !stage.delete()) throw new IOException("Cannot clear old stage");
        }
        ensureCurrent(value.ticket); pending = value;
        events.send(value.ticket, "ready", "", join(incoming.keySet()), -1);
    }

    // GML has validated and converted every stage before calling this method.
    boolean apply() {
        Pending value = pending;
        if (!busy.get() || value == null || value.chosen == null || value.ticket != generation.get()) return false;
        try {
            if (!SaveSyncFiles.same(localFiles("", false), value.live)) throw new IOException("Local progress changed");
            Set<String> names = SaveSyncFiles.merge(value.local, value.chosen.files).keySet();
            new SaveTransferFiles(root).applySync(names.toArray(new String[0]));
            value.applied = true;
            return true;
        } catch (Exception failure) { finish(value.ticket, "error", "Save import was not applied."); return false; }
    }

    // Re-export after conversion so the remembered baseline exactly matches the installed save set.
    boolean complete() {
        Pending value = pending;
        if (value == null || !value.applied) return false;
        if (!busy.get() || value == null || value.chosen == null || value.ticket != generation.get()) return false;
        try {
            final Map<String, byte[]> installed = localFiles("backupstage_", true);
            activeWork.incrementAndGet();
            worker.execute(() -> {
                try {
                    ensureCurrent(value.ticket);
                    if (value.resolved || value.heads.size() > 1 || !SaveSyncFiles.same(installed, value.chosen.files))
                        publish(value.tree, value.state, SaveSyncFiles.make(writer(), installed, value.heads), value.ticket);
                    else write(new File(value.state, "base.zip"), SaveSyncFiles.encode(value.chosen));
                    finish(value.ticket, "imported", "Shared saves were loaded.");
                } catch (Exception failure) { finish(value.ticket, "error", "Saves loaded; folder acknowledgement is pending."); }
                finally { endWork(value.ticket); }
            });
            return true;
        } catch (Exception failure) { finish(value.ticket, "error", "Saves loaded; sync needs another check."); return false; }
    }

    void cancel() {
        generation.incrementAndGet(); cancellation.cancel(); pending = null;
        if (activeWork.get() == 0) busy.set(false);
    }

    private void endWork(int ticket) {
        if (activeWork.decrementAndGet() == 0 && ticket != generation.get()) busy.set(false);
    }

    private void ensureCurrent(int ticket) throws IOException {
        if (ticket != generation.get() || cancellation.isCanceled()) throw new IOException("Sync cancelled");
    }

    private void finish(int ticket, String action, String message) {
        if (ticket != generation.get()) return;
        busy.set(false);
        if (!action.equals("conflict")) pending = null;
        events.send(ticket, action, message, "", -1);
    }

    private Map<String, byte[]> localFiles(String prefix, boolean portable) throws IOException {
        Map<String, byte[]> files = new TreeMap<>();
        for (String name : SaveSyncFiles.NAMES) {
            File file = new File(root, prefix + name);
            if (file.exists()) try (InputStream input = new FileInputStream(file)) {
                files.put(name, SaveSyncFiles.read(input, SaveSyncFiles.MAX_FILE));
            }
        }
        if (portable) SaveSyncFiles.validateFiles(files);
        return files;
    }

    private SaveSyncFiles.Snapshot saved(File file) throws IOException {
        if (!file.exists()) return null;
        try (InputStream in = new FileInputStream(file)) { return SaveSyncFiles.decode(SaveSyncFiles.read(in, SaveSyncFiles.MAX_BUNDLE)); }
    }

    private List<SaveSyncFiles.Snapshot> readShared(Uri tree, SaveSyncFiles.Snapshot queued) throws Exception {
        List<SaveSyncFiles.Snapshot> copies = new ArrayList<>();
        for (Map.Entry<String, Uri> child : children(tree, rootUri(tree)).entrySet()) {
            String name = child.getKey();
            if (!name.startsWith(SaveSyncFiles.PREFIX) || !name.endsWith(".zip")) continue;
            if (!name.matches("am2r-sync-[0-9a-f]{32}\\.zip")) throw new IOException("Conflicting transfer filename");
            if (copies.size() >= 32) throw new IOException("Too many sync copies");
            SaveSyncFiles.Snapshot copy;
            try { copy = SaveSyncFiles.decode(read(child.getValue())); }
            catch (IOException incomplete) {
                if (queued != null && name.equals(SaveSyncFiles.PREFIX + writer() + ".zip")) continue;
                throw incomplete;
            }
            if (!name.equals(SaveSyncFiles.PREFIX + copy.writer + ".zip")) throw new IOException("Mismatched save writer");
            copies.add(copy);
        }
        return copies;
    }

    private void publish(Uri tree, File state, SaveSyncFiles.Snapshot copy, int ticket) throws Exception {
        ensureCurrent(ticket);
        byte[] bytes = SaveSyncFiles.encode(copy);
        write(new File(state, "outgoing.zip"), bytes);
        Uri parent = rootUri(tree);
        String name = SaveSyncFiles.PREFIX + copy.writer + ".zip";
        Map<String, Uri> files = children(tree, parent);
        Uri target = files.get(name);
        if (target == null) target = create(parent, "application/zip", name);
        boolean same = false;
        try { same = Arrays.equals(bytes, read(target)); } catch (IOException incomplete) { }
        if (!same) store(target, bytes);
        ensureCurrent(ticket);
        write(new File(state, "base.zip"), bytes);
        File outgoing = new File(state, "outgoing.zip");
        if (outgoing.exists() && !outgoing.delete()) throw new IOException("Cannot acknowledge sync transfer");
    }

    // Recovery folders contain normal portable save files and work with existing Restore Saves.
    private void recovery(Uri tree, Map<String, byte[]> files) throws Exception {
        if (files.isEmpty()) return;
        StringBuilder content = new StringBuilder();
        for (Map.Entry<String, byte[]> entry : files.entrySet()) content.append(entry.getKey()).append(SaveSyncFiles.hash(entry.getValue()));
        String key = SaveSyncFiles.hash(content.toString().getBytes(StandardCharsets.UTF_8));
        Uri parent = folder(tree, rootUri(tree), "AM2R-Sync-Recovery");
        Uri version = folder(tree, parent, key);
        Map<String, Uri> old = children(tree, version);
        for (Map.Entry<String, byte[]> entry : files.entrySet()) {
            Uri target = old.get(entry.getKey());
            if (target == null) target = create(version, "application/octet-stream", entry.getKey());
            boolean same = false;
            try { same = Arrays.equals(entry.getValue(), read(target)); } catch (IOException incomplete) { }
            if (!same) store(target, entry.getValue());
        }
    }

    private Uri folder(Uri tree, Uri parent, String name) throws Exception {
        Uri found = children(tree, parent).get(name);
        return found != null ? found : create(parent, DocumentsContract.Document.MIME_TYPE_DIR, name);
    }

    private Uri create(Uri parent, String mime, String name) throws IOException {
        Uri result = DocumentsContract.createDocument(context.getContentResolver(), parent, mime, name);
        if (result == null) throw new IOException("Cannot create sync document");
        try (Cursor cursor = context.getContentResolver().query(result, new String[]{
                DocumentsContract.Document.COLUMN_DISPLAY_NAME, DocumentsContract.Document.COLUMN_MIME_TYPE},
                null, null, null, cancellation)) {
            if (cursor == null || !cursor.moveToFirst() || !name.equals(cursor.getString(0)) || !mime.equals(cursor.getString(1)))
                throw new IOException("Folder provider changed the document name or type");
        }
        return result;
    }

    private Uri rootUri(Uri tree) { return DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree)); }

    private Map<String, Uri> children(Uri tree, Uri parent) throws Exception {
        Uri query = DocumentsContract.buildChildDocumentsUriUsingTree(tree, DocumentsContract.getDocumentId(parent));
        Map<String, Uri> files = new TreeMap<>();
        try (Cursor cursor = context.getContentResolver().query(query, new String[]{
                DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME},
                null, null, null, cancellation)) {
            if (cursor == null) throw new IOException("Sync folder unavailable");
            int count = 0;
            while (cursor.moveToNext()) {
                if (++count > 4096) throw new IOException("Sync folder too large");
                String name = cursor.getString(1);
                if (files.put(name, DocumentsContract.buildDocumentUriUsingTree(tree, cursor.getString(0))) != null)
                    throw new IOException("Duplicate document name");
            }
        }
        return files;
    }

    private byte[] read(Uri uri) throws IOException {
        ParcelFileDescriptor file = context.getContentResolver().openFileDescriptor(uri, "r", cancellation);
        if (file == null) throw new IOException("Sync file unavailable");
        try (InputStream input = new ParcelFileDescriptor.AutoCloseInputStream(file)) {
            return SaveSyncFiles.read(input, SaveSyncFiles.MAX_BUNDLE);
        }
    }

    private void store(Uri uri, byte[] bytes) throws IOException {
        ParcelFileDescriptor file = context.getContentResolver().openFileDescriptor(uri, "wt", cancellation);
        if (file == null) throw new IOException("Sync folder is not writable");
        try (OutputStream output = new ParcelFileDescriptor.AutoCloseOutputStream(file)) {
            output.write(bytes); output.flush();
        }
        if (!Arrays.equals(bytes, read(uri))) throw new IOException("Sync readback failed");
    }

    private void write(File file, byte[] bytes) throws IOException {
        File temp = new File(file.getPath() + ".tmp");
        try (FileOutputStream out = new FileOutputStream(temp)) { out.write(bytes); out.getFD().sync(); }
        try { Os.rename(temp.getPath(), file.getPath()); }
        catch (Exception error) { throw new IOException("Cannot commit sync state", error); }
    }

    private static String join(Collection<String> names) {
        StringBuilder value = new StringBuilder();
        for (String name : names) { if (value.length() > 0) value.append(','); value.append(name); }
        return value.toString();
    }
}
