package ${YYAndroidPackageName};

import android.system.Os;
import java.io.*;
import java.security.MessageDigest;
import java.util.*;

/** Checked local save replacement. The journal is recovered before game startup. */
final class SaveTransferFiles {
    static final long MAX_BYTES = 1024 * 1024;
    private final File root, journal;

    SaveTransferFiles(File root) {
        this.root = root;
        journal = new File(root, "restore-transaction");
    }

    private static boolean slot(String name) {
        return "save1".equals(name) || "save2".equals(name) || "save3".equals(name);
    }

    synchronized void apply(String source, String target) throws Exception {
        // Finish recovery before starting another replacement, then restrict which save names may be paired.
        recover();
        String[] sources, targets;
        if (slot(source) && slot(target)) {
            sources = new String[]{source}; targets = new String[]{target};
        // Include the staged extras file when restoring the shared unlock data.
        } else if ("data.sav".equals(source) && source.equals(target)) {
            sources = new File(root, "restorestage_extras.sav").isFile()
                    ? new String[]{"data.sav", "extras.sav"} : new String[]{"data.sav"};
            targets = sources;
        } else throw new IOException("Invalid save selection");

        applyFiles(sources, targets, "restorestage_");
    }

    synchronized void applySync(String[] names) throws Exception {
        recover();
        Set<String> selected = new LinkedHashSet<>();
        if (names.length == 0 || names.length > 5) throw new IOException("Invalid sync selection");
        for (String name : names) {
            if ((!slot(name) && !name.equals("data.sav") && !name.equals("extras.sav")) || !selected.add(name))
                throw new IOException("Invalid sync selection");
            File staged = new File(root, "syncstage_" + name);
            if (!staged.isFile() || staged.length() == 0 || staged.length() > MAX_BYTES)
                throw new IOException("Missing sync stage");
        }
        if (selected.contains("data.sav") != selected.contains("extras.sav"))
            throw new IOException("Incomplete sync records");
        // Repeated syncs leave identical files and their recovery history alone.
        Set<String> changed = new LinkedHashSet<>();
        for (String name : selected) {
            File live = new File(root, name), stage = new File(root, "syncstage_" + name);
            if (!live.isFile() || !Arrays.equals(hash(live), hash(stage))) changed.add(name);
        }
        if (changed.contains("data.sav") || changed.contains("extras.sav")) {
            changed.add("data.sav"); changed.add("extras.sav");
        }
        if (changed.isEmpty()) return;
        String[] targets = changed.toArray(new String[0]);
        applyFiles(targets, targets, "syncstage_");
    }

    private void applyFiles(String[] sources, String[] targets, String prefix) throws Exception {
        File old = new File(journal, "old"), next = new File(journal, "new");
        if (!old.mkdirs() || !next.mkdir()) throw new IOException("Cannot stage restore");
        try {
            // Keep verified copies of both the incoming files and any live files before marking the journal ready.
            StringBuilder names = new StringBuilder();
            for (int i = 0; i < sources.length; i++) {
                File staged = new File(root, prefix + sources[i]);
                if (!staged.isFile() || staged.length() == 0) throw new IOException("Missing staged save");
                copy(staged, new File(next, targets[i]));
                File live = new File(root, targets[i]);
                if (live.exists()) copy(live, new File(old, targets[i]));
                names.append(targets[i]).append('\n');
            }
            write(new File(journal, "targets"), names.toString().getBytes("UTF-8"));
            // Only a ready journal may have changed live files, so recovery can distinguish an incomplete preparation.
            mark("READY");
            // rename replaces a complete file atomically, never deleting it first.
            for (String name : targets)
                Os.rename(new File(next, name).getPath(), new File(root, name).getPath());
            mark("FINISHED");
        } catch (Exception failure) {
            try { recover(); } catch (Exception recoveryFailure) { failure.addSuppressed(recoveryFailure); }
            throw failure;
        }
        // A cleanup failure cannot turn a committed restore into an error. The
        // complete journal remains available for cleanup on the next startup.
        try { archiveAndClean(); } catch (Exception retainedJournal) { }
    }

    synchronized void recover() throws Exception {
        if (!journal.exists()) return;
        // An unfinished ready journal rolls back every listed target, including files newly created by the restore.
        if (new File(journal, "READY").isFile() && !new File(journal, "FINISHED").isFile()) {
            ArrayList<String> targets = new ArrayList<>();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(
                    new FileInputStream(new File(journal, "targets")), "UTF-8"))) {
                String name;
                while ((name = reader.readLine()) != null) {
                    if ((!slot(name) && !name.equals("data.sav") && !name.equals("extras.sav"))
                            || targets.contains(name) || targets.size() >= 5)
                        throw new IOException("Invalid restore journal");
                    targets.add(name);
                }
            }
            // Restore each saved predecessor, or remove a new live file when no predecessor existed.
            for (String name : targets) {
                File previous = new File(journal, "old/" + name), live = new File(root, name);
                if (previous.isFile()) {
                    File replacement = new File(journal, "recovery");
                    copy(previous, replacement);
                    Os.rename(replacement.getPath(), live.getPath());
                } else if (live.exists() && !live.delete()) throw new IOException("Cannot undo new save");
            }
            mark("FINISHED");
        }
        archiveAndClean();
    }

    private void archiveAndClean() throws Exception {
        File old = new File(journal, "old");
        // Retain old saves in a separate snapshot before removing the transaction directory.
        if (old.isDirectory() && old.list() != null && old.list().length > 0) {
            File backups = new File(root, "pre-restore-backup");
            if (!backups.isDirectory() && !backups.mkdirs()) throw new IOException("Cannot retain recovery copy");
            File snapshot = new File(backups, System.currentTimeMillis() + "-" + UUID.randomUUID());
            Os.rename(old.getPath(), snapshot.getPath());
        }
        deleteTree(journal);
    }

    private void mark(String name) throws Exception {
        // Write and sync a marker before renaming it into the journal state used by recovery.
        File tmp = new File(journal, name + ".tmp");
        write(tmp, new byte[]{1});
        Os.rename(tmp.getPath(), new File(journal, name).getPath());
    }

    private static void write(File dst, byte[] data) throws Exception {
        try (FileOutputStream out = new FileOutputStream(dst)) {
            out.write(data); out.getFD().sync();
        }
    }

    static void copy(File src, File dst) throws Exception {
        try (InputStream in = new FileInputStream(src); FileOutputStream out = new FileOutputStream(dst)) {
            pipe(in, out); out.getFD().sync();
        }
        // A copied stage or recovery file must match both the original length and hash.
        if (src.length() != dst.length() || !Arrays.equals(hash(src), hash(dst)))
            throw new IOException("Save copy verification failed");
    }

    static byte[] hash(File file) throws Exception {
        try (InputStream in = new FileInputStream(file)) { return hash(in); }
    }

    // Hash at most one save file's allowed size, including readback from a document provider.
    static byte[] hash(InputStream in) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        byte[] buf = new byte[8192]; int n; long total = 0;
        while ((n = in.read(buf)) != -1) {
            total += n;
            if (total > MAX_BYTES) throw new IOException("Save exceeds size limit");
            digest.update(buf, 0, n);
        }
        return digest.digest();
    }

    // Bound every transferred save while streaming so oversized inputs cannot fill the destination unchecked.
    static void pipe(InputStream in, OutputStream out) throws Exception {
        if (in == null || out == null) throw new IOException("Save stream unavailable");
        byte[] buf = new byte[8192]; int n; long total = 0;
        while ((n = in.read(buf)) != -1) {
            total += n;
            if (total > MAX_BYTES) throw new IOException("Save exceeds size limit");
            out.write(buf, 0, n);
        }
        out.flush();
    }

    private static void deleteTree(File dir) throws IOException {
        File[] children = dir.listFiles();
        if (children != null) for (File child : children) deleteTree(child);
        if (dir.exists() && !dir.delete()) throw new IOException("Cannot clean restore journal");
    }
}
