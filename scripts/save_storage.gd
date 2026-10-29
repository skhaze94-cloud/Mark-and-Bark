extends RefCounted

# Promote only fully written documents. A failed write or backup rotation never
# removes the current save, and an unreadable primary never replaces a good backup.
func read_json(path: String) -> Dictionary:
	var file=FileAccess.open(path,FileAccess.READ)
	if file==null:return {}
	var text=file.get_as_text();file.close()
	var parser=JSON.new()
	if parser.parse(text)!=OK or not parser.data is Dictionary:return {}
	return parser.data

func write_text(path: String, text: String) -> Error:
	var file=FileAccess.open(path,FileAccess.WRITE)
	if file==null:return FileAccess.get_open_error()
	file.store_string(text);file.flush()
	var error=file.get_error()
	if error==OK and file.get_position()!=text.to_utf8_buffer().size():error=ERR_FILE_CANT_WRITE
	file.close()
	return error

func copy_file(from: String, to: String) -> Error:
	return DirAccess.copy_absolute(from,to)

func rename_file(from: String, to: String) -> Error:
	return DirAccess.rename_absolute(from,to)

func discard_temporary(path: String) -> void:
	if FileAccess.file_exists(path):DirAccess.remove_absolute(path)

func write_atomic(path: String, document: Dictionary, is_valid: Callable) -> Error:
	if not is_valid.call(document):return ERR_INVALID_DATA
	var pending=path+".tmp";var pending_backup=path+".bak.tmp"
	var encoded=JSON.stringify(document)
	var error=write_text(pending,encoded)
	if error==OK:
		var check=FileAccess.open(pending,FileAccess.READ)
		if check==null:error=ERR_FILE_CANT_READ
		else:
			if check.get_as_text()!=encoded:error=ERR_FILE_CORRUPT
			check.close()
	if error==OK and not is_valid.call(read_json(pending)):error=ERR_FILE_CORRUPT
	if error!=OK:
		discard_temporary(pending)
		return error
	if is_valid.call(read_json(path)):
		error=copy_file(path,pending_backup)
		if error==OK and not is_valid.call(read_json(pending_backup)):error=ERR_FILE_CORRUPT
		if error==OK:error=rename_file(pending_backup,path+".bak")
		if error!=OK:
			discard_temporary(pending);discard_temporary(pending_backup)
			return error
	error=rename_file(pending,path)
	if error!=OK:discard_temporary(pending)
	return error
