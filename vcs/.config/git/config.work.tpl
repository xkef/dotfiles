# Rendered by ./install via `op inject` from op://Work/git/.
# Active only inside ~/work/ (see [includeIf] in ../config).
# DO NOT COMMIT the rendered output (~/.config/git/config.work).

[user]
	name = {{ op://Work/git/name }}
	email = {{ op://Work/git/email }}

[commit]
	gpgsign = false

[tag]
	gpgsign = false
