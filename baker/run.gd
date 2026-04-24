# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
# Baker entrypoint — validates and exports a user-content scene.
#
# Invocation (from Elixir baker escript):
#   godot --headless --path <workspace> \
#     --script res://baker/run.gd -- avatar|map scenes/<id>.tscn out/<id>.scn
#
# Exit codes: 0 = success, 1 = validation/export failure
@tool
extends SceneTree

func _init() -> void:
	var args: Array = OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("Usage: run.gd -- avatar|map <scene_path> <out_path>")
		quit(1)
		return

	var content_type: String = args[0]
	var scene_path: String   = args[1]
	var out_path: String     = args[2]

	if not scene_path.begins_with("res://"):
		scene_path = "res://" + scene_path
	if not out_path.begins_with("res://"):
		out_path = "res://" + out_path

	var abs_out_dir: String = ProjectSettings.globalize_path(out_path.get_base_dir())
	DirAccess.make_dir_recursive_absolute(abs_out_dir)

	if not ResourceLoader.exists(scene_path):
		push_error("Scene not found: %s" % scene_path)
		quit(1)
		return

	var packed: PackedScene = ResourceLoader.load(scene_path)
	if packed == null:
		push_error("Failed to load scene: %s" % scene_path)
		quit(1)
		return

	var exporter := VSKExporter.new()
	var root := Node.new()

	match content_type:
		"avatar":
			var node: Node = packed.instantiate()
			var result: int = exporter.export_avatar(root, node, out_path)
			if result != VSKAvatarCallback.Result.AVATAR_OK:
				push_error("Avatar export failed (code %d)" % result)
				quit(1)
				return

		"map":
			var node: Node = packed.instantiate()
			var result: int = exporter.export_map(root, node, out_path)
			if result != OK:
				push_error("Map export failed (code %d)" % result)
				quit(1)
				return

		_:
			push_error("Unknown content_type '%s' (expected avatar or map)" % content_type)
			quit(1)
			return

	root.free()
	print("baker/run.gd: exported %s → %s" % [content_type, out_path])

	# ── Chunk, upload, and register the asset ───────────────────────────
	var asset_id: String = OS.get_environment("ASSET_ID")
	var uro_url: String  = OS.get_environment("URO_URL")
	if asset_id.is_empty() or uro_url.is_empty():
		push_error("ASSET_ID and URO_URL env vars are required for upload")
		quit(1)
		return

	# Read exported bytes.
	var abs_out_path: String = ProjectSettings.globalize_path(out_path)
	var file_bytes: PackedByteArray = FileAccess.get_file_as_bytes(abs_out_path)
	if file_bytes.is_empty():
		push_error("Exported file is empty or unreadable: %s" % abs_out_path)
		quit(1)
		return

	# Chunk + PUT all chunks to zone-backend's ChunkServerPlug.
	var asset_obj := FabricMMOGAsset.new()
	var chunk_store_url: String = "%s/chunks" % uro_url.rstrip("/")
	print("baker/run.gd: uploading chunks to %s" % chunk_store_url)
	var caibx_bytes: PackedByteArray = asset_obj.upload_asset_gd(chunk_store_url, file_bytes)
	if caibx_bytes.is_empty():
		push_error("baker/run.gd: upload_asset_gd failed — check log above")
		quit(1)
		return
	print("baker/run.gd: all chunks uploaded, caibx size=%d" % caibx_bytes.size())

	# POST caibx_data (base64) to /storage/:id/bake.
	# zone-backend stores the index in S3 and sets baked_url.
	var caibx_b64: String = Marshalls.raw_to_base64(caibx_bytes)
	var body_json: String = JSON.stringify({"caibx_data": caibx_b64})
	var bake_url: String = "%s/storage/%s/bake" % [uro_url.rstrip("/"), asset_id]
	print("baker/run.gd: posting bake to %s" % bake_url)
	var ok: bool = asset_obj.http_post_gd(bake_url, body_json.to_utf8_buffer(),
			"application/json")
	if not ok:
		push_error("baker/run.gd: POST to %s failed" % bake_url)
		quit(1)
		return

	print("baker/run.gd: bake complete for asset %s" % asset_id)
	quit(0)
