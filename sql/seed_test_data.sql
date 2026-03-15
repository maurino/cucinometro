-- Script per creare dati di test nel database Cucinometro
-- Membri della famiglia: mauro, daniela, silvia, claudia, alessandra, giulia, francesco
-- Crea due pasti per ogni giorno (pranzo + cena) dal 1-1-2025 a oggi.

-- Pulisce completamente il database
DELETE FROM dishwashing_assignment;
DELETE FROM meal_participant;
DELETE FROM meal;
DELETE FROM family_member;
SELECT setval('family_member_id_seq', 1, false);
SELECT setval('meal_id_seq', 1, false);
SELECT setval('dishwashing_assignment_id_seq', 1, false);

-- Inserisci membri della famiglia (solo se non esistono già)
INSERT INTO family_member (name) VALUES
('mauro'),
('daniela'),
('silvia'),
('claudia'),
('alessandra'),
('giulia'),
('francesco')
ON CONFLICT (name) DO NOTHING;

-- Crea pasti dal 1-1-2026 fino a oggi con combinazioni completamente casuali
DO $$
DECLARE
    curr_date DATE := '2025-01-01';
    end_date DATE := CURRENT_DATE;
    meal_id_var INTEGER;
    participants INTEGER[];
    assignment_member_id INTEGER;
    random_val FLOAT;
    num_participants INTEGER;
    available_members INTEGER[] := ARRAY[1,2,3,4,5,6,7];
    shuffled_members INTEGER[];
    i INTEGER;
BEGIN
    WHILE curr_date <= end_date LOOP

        -- PRANZO: Genera combinazione completamente casuale
        -- Numero di partecipanti casuale (da 1 a 7)
        num_participants := floor(random() * 7 + 1)::INTEGER;

        -- Mischia l'array dei membri disponibili e prendi i primi N
        shuffled_members := available_members;
        -- Fisher-Yates shuffle semplificato
        FOR i IN 1..7 LOOP
            DECLARE
                j INTEGER := floor(random() * (8 - i) + i)::INTEGER;
                temp INTEGER;
            BEGIN
                temp := shuffled_members[i];
                shuffled_members[i] := shuffled_members[j];
                shuffled_members[j] := temp;
            END;
        END LOOP;

        -- Prendi i primi num_participants membri mescolati
        participants := shuffled_members[1:num_participants];

        -- Crea pranzo
        INSERT INTO meal (date, kind) VALUES (curr_date, 'lunch')
        RETURNING id INTO meal_id_var;

        -- Aggiungi partecipanti al pranzo
        FOR i IN 1..array_length(participants, 1) LOOP
            INSERT INTO meal_participant (meal_id, member_id)
            VALUES (meal_id_var, participants[i]);
        END LOOP;

        -- Assegna lavapiatti usando probabilità irregolari (non equo)
        random_val := random();
        IF array_length(participants, 1) >= 1 AND random_val < 0.15 THEN assignment_member_id := participants[1]; -- 15%
        ELSIF array_length(participants, 1) >= 2 AND random_val < 0.30 THEN assignment_member_id := participants[2]; -- 15%
        ELSIF array_length(participants, 1) >= 3 AND random_val < 0.50 THEN assignment_member_id := participants[3]; -- 20%
        ELSIF array_length(participants, 1) >= 4 AND random_val < 0.65 THEN assignment_member_id := participants[4]; -- 15%
        ELSIF array_length(participants, 1) >= 5 AND random_val < 0.80 THEN assignment_member_id := participants[5]; -- 15%
        ELSIF array_length(participants, 1) >= 6 AND random_val < 0.90 THEN assignment_member_id := participants[6]; -- 10%
        ELSIF array_length(participants, 1) >= 7 THEN assignment_member_id := participants[7]; -- 10%
        ELSE assignment_member_id := participants[1]; -- fallback
        END IF;

        -- Assicurati che il membro scelto sia tra i partecipanti
        IF NOT (assignment_member_id = ANY(participants)) THEN
            assignment_member_id := participants[1];
        END IF;

        INSERT INTO dishwashing_assignment (meal_id, member_id)
        VALUES (meal_id_var, assignment_member_id);

        -- CENA: Genera combinazione completamente casuale (indipendente dal pranzo)
        -- Numero di partecipanti casuale (da 1 a 7)
        num_participants := floor(random() * 7 + 1)::INTEGER;

        -- Mischia nuovamente l'array
        shuffled_members := available_members;
        FOR i IN 1..7 LOOP
            DECLARE
                j INTEGER := floor(random() * (8 - i) + i)::INTEGER;
                temp INTEGER;
            BEGIN
                temp := shuffled_members[i];
                shuffled_members[i] := shuffled_members[j];
                shuffled_members[j] := temp;
            END;
        END LOOP;

        -- Prendi i primi num_participants membri mescolati
        participants := shuffled_members[1:num_participants];

        -- Crea cena
        INSERT INTO meal (date, kind) VALUES (curr_date, 'dinner')
        RETURNING id INTO meal_id_var;

        -- Aggiungi partecipanti alla cena
        FOR i IN 1..array_length(participants, 1) LOOP
            INSERT INTO meal_participant (meal_id, member_id)
            VALUES (meal_id_var, participants[i]);
        END LOOP;

        -- Assegna lavapiatti con probabilità ancora più irregolari per la cena
        random_val := random();
        IF array_length(participants, 1) >= 1 AND random_val < 0.10 THEN assignment_member_id := participants[1]; -- 10%
        ELSIF array_length(participants, 1) >= 2 AND random_val < 0.25 THEN assignment_member_id := participants[2]; -- 15%
        ELSIF array_length(participants, 1) >= 3 AND random_val < 0.50 THEN assignment_member_id := participants[3]; -- 25%
        ELSIF array_length(participants, 1) >= 4 AND random_val < 0.70 THEN assignment_member_id := participants[4]; -- 20%
        ELSIF array_length(participants, 1) >= 5 AND random_val < 0.85 THEN assignment_member_id := participants[5]; -- 15%
        ELSIF array_length(participants, 1) >= 6 AND random_val < 0.95 THEN assignment_member_id := participants[6]; -- 10%
        ELSIF array_length(participants, 1) >= 7 THEN assignment_member_id := participants[7]; -- 5%
        ELSE assignment_member_id := participants[1]; -- fallback
        END IF;

        -- Assicurati che il membro scelto sia tra i partecipanti
        IF NOT (assignment_member_id = ANY(participants)) THEN
            assignment_member_id := participants[1];
        END IF;

        INSERT INTO dishwashing_assignment (meal_id, member_id)
        VALUES (meal_id_var, assignment_member_id);

        curr_date := curr_date + INTERVAL '1 day';
    END LOOP;
END $$;