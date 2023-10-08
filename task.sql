BEGIN;

CREATE TEMPORARY TABLE Intervals (
	"StartDateTime" TIMESTAMP,
	"EndDateTime" TIMESTAMP
) ON COMMIT DROP;

INSERT INTO Intervals VALUES ('2018-01-01 06:00:00', '2018-01-01 14:00:00'),
							 ('2018-01-01 11:00:00', '2018-01-01 19:00:00'),
							 ('2018-01-01 20:00:00', '2018-01-02 03:00:00'),
							 ('2018-01-02 06:00:00', '2018-01-02 14:00:00'),
							 ('2018-01-02 11:00:00', '2018-01-02 19:00:00');
							 
CREATE TEMPORARY TABLE merged_intervals (
	"StartDateTime" TIMESTAMP,
	"EndDateTime" TIMESTAMP
) ON COMMIT PRESERVE ROWS;

DO $$
DECLARE
	prev_start TIMESTAMP;
	prev_end TIMESTAMP;
	curr_start TIMESTAMP;
	curr_end TIMESTAMP;
BEGIN
	SELECT * INTO prev_start, prev_end
	FROM Intervals 
	ORDER BY "StartDateTime", "EndDateTime"
	LIMIT 1;
	FOR curr_start, curr_end IN (SELECT * FROM Intervals ORDER BY "StartDateTime", "EndDateTime")
	LOOP
		IF prev_end > curr_start THEN 
			IF curr_end > prev_end THEN
				prev_end := curr_end;
			END IF;
		ELSE
			INSERT INTO merged_intervals VALUES (prev_start, prev_end);
			prev_start := curr_start;
			prev_end := curr_end;
		END IF;
	END LOOP;
	INSERT INTO merged_intervals VALUES (prev_start, prev_end);
END;
$$;

COMMIT;


-- После коммита входная временная таблица удаляется
DO $$
BEGIN
	SELECT * FROM Intervals;
EXCEPTION 
	WHEN undefined_table THEN
		RAISE NOTICE 'No such table';
END;
$$;


-- Выходная временная таблица остается до завершения сессии
SELECT * FROM merged_intervals;



