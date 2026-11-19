package ${YYAndroidPackageName};

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;
import java.util.zip.*;

/** Complete save sets and revision comparisons, independent of the folder provider. */
final class SaveSyncFiles {
    static final String[] NAMES = {"save1", "save2", "save3", "data.sav", "extras.sav"};
    static final int MAX_FILE = 1024 * 1024, MAX_BUNDLE = 5 * MAX_FILE + 65536;
    static final int UNCHANGED = 0, PUBLISH = 1, IMPORT = 2, CONFLICT = 3, DEFER = 4;
    static final String PREFIX = "am2r-sync-";

    static final class Snapshot {
        final String writer;
        final long created;
        final SortedMap<String, Long> clock;
        final SortedMap<String, byte[]> files;
        Snapshot(String writer, long created, Map<String, Long> clock, Map<String, byte[]> files) {
            this.writer = writer; this.created = created;
            this.clock = Collections.unmodifiableSortedMap(new TreeMap<>(clock));
            SortedMap<String, byte[]> copy = new TreeMap<>();
            for (Map.Entry<String, byte[]> file : files.entrySet()) copy.put(file.getKey(), file.getValue().clone());
            this.files = Collections.unmodifiableSortedMap(copy);
        }
    }

    static final class Decision {
        final int action;
        final Snapshot snapshot;
        final List<Snapshot> candidates;
        Decision(int action, Snapshot snapshot, List<Snapshot> candidates) {
            this.action = action; this.snapshot = snapshot; this.candidates = candidates;
        }
    }

    static boolean token(String value) { return value != null && value.matches("[0-9a-f]{32}"); }
    static boolean name(String value) { return Arrays.asList(NAMES).contains(value); }

    static void validateFiles(Map<String, byte[]> files) throws IOException {
        if (files.size() > NAMES.length) throw new IOException("Too many save files");
        for (Map.Entry<String, byte[]> entry : files.entrySet()) {
            if (!name(entry.getKey()) || entry.getValue() == null || entry.getValue().length == 0
                    || entry.getValue().length > MAX_FILE) throw new IOException("Invalid save file");
        }
        if (files.containsKey("data.sav") != files.containsKey("extras.sav"))
            throw new IOException("Incomplete unlock records");
    }

    // A new revision remembers every observed parent, rather than trusting device clocks.
    static Snapshot make(String writer, Map<String, byte[]> files, List<Snapshot> parents) throws IOException {
        if (!token(writer)) throw new IOException("Invalid writer token");
        validateFiles(files);
        SortedMap<String, Long> clock = new TreeMap<>();
        for (Snapshot parent : parents) for (Map.Entry<String, Long> e : parent.clock.entrySet())
            clock.put(e.getKey(), Math.max(clock.containsKey(e.getKey()) ? clock.get(e.getKey()) : 0, e.getValue()));
        long next = clock.containsKey(writer) ? clock.get(writer) + 1 : 1;
        if (next > 1000000000000L) throw new IOException("Revision limit reached");
        clock.put(writer, next);
        if (clock.size() > 32) throw new IOException("Too many sync installations");
        return new Snapshot(writer, System.currentTimeMillis(), clock, files);
    }

    static boolean same(Map<String, byte[]> a, Map<String, byte[]> b) {
        if (!a.keySet().equals(b.keySet())) return false;
        for (String name : a.keySet()) if (!Arrays.equals(a.get(name), b.get(name))) return false;
        return true;
    }

    static Map<String, byte[]> merge(Map<String, byte[]> local, Map<String, byte[]> incoming) throws IOException {
        validateFiles(local); validateFiles(incoming);
        Map<String, byte[]> result = new TreeMap<>(local);
        result.putAll(incoming); // An absent incoming slot is never a deletion request.
        return result;
    }

    static boolean dominates(Snapshot a, Snapshot b) {
        boolean greater = false;
        Set<String> writers = new HashSet<>(a.clock.keySet()); writers.addAll(b.clock.keySet());
        for (String writer : writers) {
            long x = a.clock.containsKey(writer) ? a.clock.get(writer) : 0;
            long y = b.clock.containsKey(writer) ? b.clock.get(writer) : 0;
            if (x < y) return false;
            greater |= x > y;
        }
        return greater;
    }

    static List<Snapshot> heads(List<Snapshot> all) throws IOException {
        List<Snapshot> result = new ArrayList<>();
        for (Snapshot candidate : all) {
            boolean old = false;
            for (Snapshot other : all) {
                if (candidate == other) continue;
                if (candidate.clock.equals(other.clock) && !same(candidate.files, other.files))
                    throw new IOException("Conflicting copies of the same revision");
                if (dominates(other, candidate)) old = true;
            }
            for (Snapshot kept : result) if (kept.clock.equals(candidate.clock)) old = true;
            if (!old) result.add(candidate);
        }
        return result;
    }

    // Only unchanged local progress can accept a remote update automatically.
    static Decision plan(String writer, Map<String, byte[]> local, Snapshot base,
                         List<Snapshot> remote, boolean allowImport) throws IOException {
        validateFiles(local);
        List<Snapshot> all = new ArrayList<>(remote);
        if (base != null) all.add(base);
        List<Snapshot> heads = heads(all);
        if (heads.isEmpty()) return new Decision(local.isEmpty() ? UNCHANGED : PUBLISH,
                local.isEmpty() ? null : make(writer, local, heads), heads);
        Snapshot newest = heads.get(0);
        for (Snapshot h : heads) if (!same(h.files, newest.files)) return new Decision(CONFLICT, null, heads);
        if (same(local, newest.files)) return new Decision(heads.size() == 1 ? UNCHANGED : PUBLISH,
                heads.size() == 1 ? newest : make(writer, local, heads), heads);
        if (base != null && same(base.files, newest.files))
            return new Decision(PUBLISH, make(writer, local, heads), heads);
        if ((base == null && local.isEmpty()) || (base != null && same(local, base.files)))
            return new Decision(allowImport ? IMPORT : DEFER, newest, heads);
        return new Decision(CONFLICT, null, heads);
    }

    static String hash(byte[] data) throws IOException {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(data);
            StringBuilder out = new StringBuilder();
            for (byte value : digest) out.append(String.format(Locale.ROOT, "%02x", value & 255));
            return out.toString();
        } catch (Exception failure) { throw new IOException("Cannot check save contents", failure); }
    }

    static byte[] read(InputStream input, int limit) throws IOException {
        if (input == null) throw new IOException("Save stream unavailable");
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] buffer = new byte[8192]; int count;
        while ((count = input.read(buffer)) != -1) {
            if (out.size() + count > limit) throw new IOException("Save size limit exceeded");
            out.write(buffer, 0, count);
        }
        return out.toByteArray();
    }

    static byte[] encode(Snapshot snapshot) throws IOException {
        validateFiles(snapshot.files);
        StringBuilder manifest = new StringBuilder("AM2R-SaveSync-1\n");
        manifest.append("writer=").append(snapshot.writer).append('\n');
        manifest.append("created=").append(snapshot.created).append('\n');
        for (Map.Entry<String, Long> e : snapshot.clock.entrySet())
            manifest.append("clock.").append(e.getKey()).append('=').append(e.getValue()).append('\n');
        for (Map.Entry<String, byte[]> e : snapshot.files.entrySet())
            manifest.append("file.").append(e.getKey()).append('=').append(hash(e.getValue())).append('\n');
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        try (ZipOutputStream zip = new ZipOutputStream(bytes)) {
            entry(zip, "manifest.txt", manifest.toString().getBytes(StandardCharsets.UTF_8));
            for (Map.Entry<String, byte[]> e : snapshot.files.entrySet()) entry(zip, e.getKey(), e.getValue());
        }
        if (bytes.size() > MAX_BUNDLE) throw new IOException("Save bundle too large");
        return bytes.toByteArray();
    }

    private static void entry(ZipOutputStream zip, String name, byte[] bytes) throws IOException {
        ZipEntry entry = new ZipEntry(name); entry.setTime(0);
        zip.putNextEntry(entry); zip.write(bytes); zip.closeEntry();
    }

    private static long little(byte[] bytes, int at, int length) {
        long result = 0;
        for (int i = 0; i < length; i++) result |= (long) (bytes[at + i] & 255) << (8 * i);
        return result;
    }

    static Snapshot decode(byte[] bytes) throws IOException {
        // Require a complete ZIP footer as well as entry CRCs and explicit content hashes.
        int end = bytes.length - 22;
        if (end < 0 || bytes.length > MAX_BUNDLE || little(bytes, end, 4) != 0x06054b50L
                || little(bytes, end + 4, 4) != 0 || little(bytes, end + 20, 2) != 0
                || little(bytes, end + 12, 4) + little(bytes, end + 16, 4) != end)
            throw new IOException("Incomplete save bundle");
        Map<String, byte[]> files = new TreeMap<>(); byte[] metadata = null;
        Set<String> seen = new HashSet<>(); int total = 0;
        try (ZipInputStream zip = new ZipInputStream(new ByteArrayInputStream(bytes))) {
            ZipEntry entry;
            while ((entry = zip.getNextEntry()) != null) {
                String name = entry.getName();
                if (entry.isDirectory() || !seen.add(name) || (!name(name) && !name.equals("manifest.txt")))
                    throw new IOException("Unexpected save entry");
                byte[] content = read(zip, name.equals("manifest.txt") ? 8192 : MAX_FILE);
                total += content.length;
                if (total > MAX_BUNDLE) throw new IOException("Save bundle too large");
                if (name.equals("manifest.txt")) metadata = content; else files.put(name, content);
                zip.closeEntry();
            }
        }
        if (metadata == null || little(bytes, end + 8, 2) != seen.size()
                || little(bytes, end + 10, 2) != seen.size()) throw new IOException("Missing save manifest");
        validateFiles(files);
        String[] lines = new String(metadata, StandardCharsets.UTF_8).split("\n");
        if (lines.length < 4 || !lines[0].equals("AM2R-SaveSync-1")) throw new IOException("Unknown save bundle format");
        Map<String, String> fields = new TreeMap<>(); SortedMap<String, Long> clock = new TreeMap<>();
        for (int i = 1; i < lines.length; i++) {
            int equals = lines[i].indexOf('=');
            if (equals <= 0 || equals == lines[i].length() - 1) throw new IOException("Invalid save manifest");
            String key = lines[i].substring(0, equals), value = lines[i].substring(equals + 1);
            if (fields.put(key, value) != null) throw new IOException("Duplicate save manifest field");
        }
        String writer = fields.remove("writer"), stamp = fields.remove("created");
        if (!token(writer)) throw new IOException("Invalid writer token");
        long created = number(stamp, Long.MAX_VALUE);
        for (String key : new ArrayList<>(fields.keySet())) if (key.startsWith("clock.")) {
            String device = key.substring(6);
            if (!token(device)) throw new IOException("Invalid revision token");
            clock.put(device, number(fields.remove(key), 1000000000000L));
        }
        if (!clock.containsKey(writer) || clock.size() > 32) throw new IOException("Invalid revision list");
        for (Map.Entry<String, byte[]> file : files.entrySet())
            if (!hash(file.getValue()).equals(fields.remove("file." + file.getKey())))
                throw new IOException("Save checksum mismatch");
        if (!fields.isEmpty()) throw new IOException("Unexpected save manifest field");
        return new Snapshot(writer, created, clock, files);
    }

    private static long number(String text, long limit) throws IOException {
        try {
            if (text == null || !text.matches("[1-9][0-9]{0,18}")) throw new NumberFormatException();
            long value = Long.parseLong(text);
            if (value > limit) throw new NumberFormatException();
            return value;
        } catch (NumberFormatException failure) { throw new IOException("Invalid save revision", failure); }
    }
}
