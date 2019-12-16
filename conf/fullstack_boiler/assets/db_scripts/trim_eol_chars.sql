update
	some_table
set
	"name" = regexp_replace("name", E'[\\n\\r]+', ' ', 'g' ),