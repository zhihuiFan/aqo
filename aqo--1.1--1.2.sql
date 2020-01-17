CREATE OR REPLACE FUNCTION aqo_migrate_to_1_2_get_pk(relid regclass) RETURNS text AS $$
DECLARE
	res text;
BEGIN
	SELECT conname
		FROM pg_constraint
		WHERE conrelid = relid AND contype = 'u'
	INTO res;

	RETURN res;
END
$$ LANGUAGE plpgsql;

DO $$
BEGIN
	EXECUTE format('ALTER TABLE public.aqo_data DROP CONSTRAINT %s',
				   aqo_migrate_to_1_2_get_pk('aqo_data'::regclass),
				   'aqo_queries_query_hash_idx');
END
$$;


DROP FUNCTION aqo_migrate_to_1_2_get_pk(regclass);

--
-- Service functions
--
CREATE FUNCTION public.aqo_status(hash int)
RETURNS TABLE (
	"learn"			BOOL,
	"use aqo"		BOOL,
	"auto tune"		BOOL,
	"fspace hash"	INT,
	"aqo error"		TEXT,
	"base error"	TEXT
) 
AS $func$
SELECT	learn_aqo,use_aqo,auto_tuning,fspace_hash,
		to_char(cardinality_error_with_aqo[n1],'9.99EEEE'),
		to_char(cardinality_error_without_aqo[n2],'9.99EEEE')
FROM aqo_queries aq, aqo_query_stat aqs,
	(SELECT array_length(n1,1) AS n1, array_length(n2,1) AS n2 FROM 
		(SELECT cardinality_error_with_aqo AS n1, cardinality_error_without_aqo AS n2
		FROM aqo_query_stat aqs WHERE
		aqs.query_hash = $1) AS al) AS q
WHERE (aqs.query_hash = aq.query_hash) AND
	aqs.query_hash = $1;
$func$ LANGUAGE SQL;

