// Linux folder access and checked progress replacement for the in-game Data menu.
#include <algorithm>
#include <cerrno>
#include <cctype>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <set>
#include <stdexcept>
#include <string>
#include <vector>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

namespace fs = std::filesystem;
namespace {
constexpr size_t limit = 1024 * 1024;
const std::vector<std::string> names = {"save1", "save2", "save3", "data.sav", "extras.sav"};
fs::path root;
std::string reply;
struct FD {
    int n;
    explicit FD(int value) : n(value) { if (n < 0) throw std::runtime_error("File access failed"); }
    ~FD() { close(n); }
    FD(const FD&) = delete;
};

bool present(const fs::path& p) { return fs::symlink_status(p).type() != fs::file_type::not_found; }
bool allowed(const std::string& n) { return std::find(names.begin(), names.end(), n) != names.end(); }
bool slot(const std::string& n) { return n == "save1" || n == "save2" || n == "save3"; }
void require(bool condition) { if (!condition) throw std::runtime_error("Invalid save operation"); }
void ready() { require(!root.empty() && fs::is_directory(root)); }

void directory(const fs::path& p) {
    if (!present(p)) fs::create_directory(p);
    require(!fs::is_symlink(p) && fs::is_directory(p));
}

void sync_dir(const fs::path& p) {
    FD fd(open(p.c_str(), O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW));
    if (fsync(fd.n) && errno != EINVAL && errno != ENOTSUP)
        throw std::runtime_error("Folder sync failed");
}

std::string read(const fs::path& p) {
    FD fd(open(p.c_str(), O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK));
    struct stat st {};
    require(fstat(fd.n, &st) == 0 && S_ISREG(st.st_mode) && st.st_size > 0 && size_t(st.st_size) <= limit);
    std::string value(size_t(st.st_size), '\0');
    size_t done = 0;
    while (done < value.size()) {
        ssize_t n = ::read(fd.n, value.data() + done, value.size() - done);
        if (n < 0 && errno == EINTR) continue;
        require(n > 0);
        done += size_t(n);
    }
    char extra;
    require(::read(fd.n, &extra, 1) == 0);
    return value;
}

void write_new(const fs::path& p, const std::string& bytes) {
    require(!bytes.empty() && bytes.size() <= limit);
    FD fd(open(p.c_str(), O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW, 0600));
    size_t done = 0;
    while (done < bytes.size()) {
        ssize_t n = ::write(fd.n, bytes.data() + done, bytes.size() - done);
        if (n < 0 && errno == EINTR) continue;
        require(n > 0);
        done += size_t(n);
    }
    require(fsync(fd.n) == 0);
    require(read(p) == bytes);
}

void copy_checked(const fs::path& from, const fs::path& to) { write_new(to, read(from)); }

std::string quote(const std::string& value) {
    std::string result = "\"";
    for (unsigned char ch : value) {
        if (ch == '"' || ch == '\\') { result += '\\'; result += char(ch); }
        else if (ch < 32) {
            const char hex[] = "0123456789abcdef";
            result += "\\u00"; result += hex[ch >> 4]; result += hex[ch & 15];
        } else result += char(ch);
    }
    return result + '"';
}

const char* answer(std::string value) { reply = std::move(value); return reply.c_str(); }
const char* failed() { return answer("{\"ok\":false,\"files\":0}"); }

fs::path unique_folder(const fs::path& parent, const std::string& prefix) {
    std::string pattern = (parent / (prefix + "XXXXXX")).string();
    require(mkdtemp(pattern.data()) != nullptr);
    return fs::path(pattern);
}

fs::path journal() { return root / "restore-transaction-linux"; }
void marker(const std::string& name) {
    fs::path p = journal() / (name + ".tmp");
    if (present(p)) { require(fs::is_regular_file(fs::symlink_status(p))); fs::remove(p); }
    write_new(p, "1");
    fs::rename(p, journal() / name);
    sync_dir(journal());
}

void archive() {
    fs::path j = journal(), old = j / "old";
    if (present(old)) {
        require(!fs::is_symlink(old) && fs::is_directory(old));
        if (!fs::is_empty(old)) {
            fs::path backups = root / "pre-restore-backup";
            directory(backups);
            fs::path snapshot = unique_folder(backups, "restore-");
            fs::rename(old, snapshot);
            sync_dir(snapshot); sync_dir(backups);
        }
    }
    fs::remove_all(j);
    sync_dir(root);
}

void recover() {
    fs::path j = journal();
    if (!present(j)) return;
    require(!fs::is_symlink(j) && fs::is_directory(j));
    if (present(j / "READY") && !present(j / "FINISHED")) {
        require(read(j / "READY") == "1");
        std::string list = read(j / "targets");
        std::vector<std::string> targets;
        std::set<std::string> seen;
        size_t begin = 0;
        while (begin < list.size()) {
            size_t end = list.find('\n', begin);
            require(end != std::string::npos);
            std::string name = list.substr(begin, end - begin);
            require(allowed(name) && seen.insert(name).second && seen.size() <= names.size());
            targets.push_back(name); begin = end + 1;
        }
        require(!targets.empty());
        require(!fs::is_symlink(j / "old") && fs::is_directory(j / "old"));
        for (const auto& name : targets) {
            fs::path live = root / name, old = j / "old" / name;
            require(!present(live) || fs::is_regular_file(fs::symlink_status(live)));
            if (present(old)) {
                fs::path temp = j / "recovery";
                if (present(temp)) { require(fs::is_regular_file(fs::symlink_status(temp))); fs::remove(temp); }
                copy_checked(old, temp);
                fs::rename(temp, live);
            } else if (present(live)) fs::remove(live);
        }
        sync_dir(root);
        marker("FINISHED");
    }
    archive();
}

void clear_stages() {
    for (const auto& name : names) {
        fs::path p = root / ("restorestage_" + name);
        if (present(p)) { require(!fs::is_directory(fs::symlink_status(p))); fs::remove(p); }
    }
}
}

extern "C" double AM2ARM_SaveInit(const char* path) {
    try {
        root.clear();
        require(path && fs::path(path).is_absolute() && fs::is_directory(path));
        root = fs::canonical(path);
        recover();
        return 1;
    } catch (...) { root.clear(); return 0; }
}

extern "C" const char* AM2ARM_SaveList(const char* path) {
    try {
        ready();
        fs::path p = path && *path ? fs::path(path) : root;
        require(p.is_absolute()); p = fs::canonical(p);
        require(fs::is_directory(p));
        std::vector<std::string> dirs;
        for (const auto& item : fs::directory_iterator(p, fs::directory_options::skip_permission_denied)) {
            auto name = item.path().filename().string();
            std::error_code ec;
            if (!name.empty() && name[0] != '.' && item.is_directory(ec)) dirs.push_back(name);
            require(dirs.size() <= 8192);
        }
        auto lower = [](std::string s) { for (char& c : s) c = char(std::tolower(static_cast<unsigned char>(c))); return s; };
        std::sort(dirs.begin(), dirs.end(), [&](const auto& a, const auto& b) { return lower(a) < lower(b); });
        std::string result = "{\"ok\":true,\"path\":" + quote(p.string()) + ",\"parent\":" + quote(p.parent_path().string()) + ",\"dirs\":[";
        for (size_t i = 0; i < dirs.size(); ++i) {
            if (i) result += ',';
            result += "{\"name\":" + quote(dirs[i]) + ",\"path\":" + quote((p / dirs[i]).string()) + '}';
        }
        result += "],\"files\":0}";
        return answer(result);
    } catch (...) { return failed(); }
}

extern "C" const char* AM2ARM_SaveExport(const char* path) {
    fs::path temporary;
    try {
        ready(); require(path && fs::path(path).is_absolute());
        fs::path parent = fs::canonical(path);
        require(fs::is_directory(parent));
        temporary = unique_folder(parent, ".am2arm-backup-");
        int count = 0;
        for (const auto& name : names) {
            fs::path staged = root / ("backupstage_" + name);
            if (present(staged)) { copy_checked(staged, temporary / name); ++count; }
        }
        require(count > 0); sync_dir(temporary);
        // The random suffix avoids clock dependence and preserves earlier backups.
        fs::path final = parent / ("AM2ARM-Backup-" + temporary.filename().string().substr(15));
        require(!present(final)); fs::rename(temporary, final); temporary.clear(); sync_dir(parent);
        return answer("{\"ok\":true,\"files\":" + std::to_string(count) + ",\"path\":" + quote(final.string()) + '}');
    } catch (...) {
        if (!temporary.empty()) { std::error_code ec; fs::remove_all(temporary, ec); }
        return failed();
    }
}

extern "C" const char* AM2ARM_SaveImport(const char* path) {
    try {
        ready(); clear_stages();
        require(path && fs::path(path).is_absolute());
        fs::path from = fs::canonical(path); require(fs::is_directory(from));
        int count = 0;
        for (const auto& name : names) {
            fs::path source = from / name;
            if (present(source)) { copy_checked(source, root / ("restorestage_" + name)); ++count; }
        }
        require(count > 0);
        return answer("{\"ok\":true,\"files\":" + std::to_string(count) + '}');
    } catch (...) {
        try { if (!root.empty()) clear_stages(); } catch (...) { }
        return failed();
    }
}

extern "C" double AM2ARM_SaveApply(const char* source, const char* target) {
    try {
        ready(); recover();
        require(source && target);
        std::vector<std::string> sources, targets;
        if (slot(source) && slot(target)) { sources = {source}; targets = {target}; }
        else {
            require(std::string(source) == "data.sav" && std::string(target) == "data.sav");
            sources = {"data.sav"};
            if (present(root / "restorestage_extras.sav")) sources.push_back("extras.sav");
            targets = sources;
        }
        fs::path j = journal(); require(fs::create_directory(j));
        directory(j / "old"); directory(j / "new");
        try {
            std::string list;
            for (size_t i = 0; i < targets.size(); ++i) {
                copy_checked(root / ("restorestage_" + sources[i]), j / "new" / targets[i]);
                fs::path live = root / targets[i];
                if (present(live)) copy_checked(live, j / "old" / targets[i]);
                list += targets[i] + '\n';
            }
            write_new(j / "targets", list);
            sync_dir(j / "old"); sync_dir(j / "new"); sync_dir(j); sync_dir(root);
            marker("READY");
            for (const auto& name : targets) fs::rename(j / "new" / name, root / name);
            sync_dir(root); marker("FINISHED");
        } catch (...) { recover(); throw; }
        // Completed replacement remains successful if later archive cleanup fails.
        try { archive(); } catch (...) { }
        return 1;
    } catch (...) { return 0; }
}
