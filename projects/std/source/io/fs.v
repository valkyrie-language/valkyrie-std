namespace std.io;

micro get_current_directory() -> utf8 {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.io.directory_get_current_directory()
        <% case "jvm" %>
        return std.adaptor.jvm.system.jvm_get_property("user.dir")
        <% else %>
        return ""
    <% end match %>
}

micro file_exists(path: utf8) -> bool {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.io.file_exists(path)
        <% case "jvm" %>
        return std.adaptor.jvm.io.jvm_file_exists(path)
        <% else %>
        return false
    <% end match %>
}

micro directory_exists(path: utf8) -> bool {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.io.directory_exists(path)
        <% case "jvm" %>
        return std.adaptor.jvm.io.jvm_is_directory(path)
        <% else %>
        return false
    <% end match %>
}

micro create_directory(path: utf8) -> bool {
    <% match arch %>
        <% case "clr" %>
        std.adaptor.clr.io.directory_create(path)
        return true
        <% case "jvm" %>
        return std.adaptor.jvm.io.jvm_mkdirs(path)
        <% else %>
        return false
    <% end match %>
}

micro read_file_text(path: utf8) -> utf8 {
    <% match arch %>
        <% case "clr" %>
        return std.adaptor.clr.io.file_read_all_text(path)
        <% case "jvm" %>
        let handle: i32 = std.adaptor.jvm.io.jvm_path_of(path)
        return std.adaptor.jvm.io.jvm_file_read_all_text(handle)
        <% else %>
        return ""
    <% end match %>
}

micro write_file_text(path: utf8, content: utf8) -> bool {
    <% match arch %>
        <% case "clr" %>
        std.adaptor.clr.io.file_write_all_text(path, content)
        return true
        <% case "jvm" %>
        let handle: i32 = std.adaptor.jvm.io.jvm_path_of(path)
        std.adaptor.jvm.io.jvm_file_write_all_text(handle, content)
        return true
        <% else %>
        return false
    <% end match %>
}
