extends "res://scripts/save_storage.gd"

var fault=""

func write_text(path: String, text: String) -> Error:
	if fault in ["partial_write","silent_short_write"]:
		super.write_text(path,text.left(9))
		return ERR_FILE_CANT_WRITE if fault=="partial_write" else OK
	return super.write_text(path,text)

func copy_file(from: String, to: String) -> Error:
	if fault=="backup_copy":return ERR_FILE_CANT_WRITE
	if fault=="corrupt_backup":
		super.write_text(to,"{interrupted")
		return OK
	return super.copy_file(from,to)

func rename_file(from: String, to: String) -> Error:
	if fault=="backup_publish" and from.ends_with(".bak.tmp"):return ERR_CANT_CREATE
	if fault=="primary_publish" and not from.ends_with(".bak.tmp"):return ERR_CANT_CREATE
	return super.rename_file(from,to)
