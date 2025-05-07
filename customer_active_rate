create
    definer = reportuser@`%` procedure sp_ops_entouch_calculate_set_total_submissions()
begin
    DECLARE done INT DEFAULT 0;
    DECLARE set_id INT;
    DECLARE set_activity_month DATE;

    DECLARE cur CURSOR FOR
        SELECT s.id AS set_id, set_activity_month
        FROM 497system.497set s
        WHERE s.set_type = 'SUBMISSION'
          AND s.set_schema = 'ENTOUCH'
          AND s.set_status = 'COMPLETED'
          AND s.set_activity_month >= CURDATE() - INTERVAL 18 MONTH;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DELETE FROM entouch_set_total_submissions;

    OPEN cur;

    read_loop:
    LOOP
        FETCH cur INTO set_id, set_activity_month;
        IF done THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO entouch_set_total_submissions (set_activity_month, tribal_flag, state, agent_class,
                                                   master_fusion_id, master_name, total_submissions)
        SELECT sd.set_activity_month                                    as set_activity_month,
               sd.sdata_tribal_flag                                     as tribal_flag,
               sd.sdata_state                                           as state,
               sd.sdata_agent_class                                     as agent_class,
               ifnull(mas.account, ifnull(man.account, rep.account))    as master_fusion_id,
               ifnull(concat(mas.firstname, ' ', mas.lastname),
                      ifnull(concat(man.firstname, ' ', man.lastname),
                             concat(rep.firstname, ' ', rep.lastname))) as master_name,
               COUNT(1)                                                 as total_submissions
        FROM 497entouch.497set_data sd
                 left join qt208.agents rep on rep.account = sd.sdata_agent_id
                 left join qt208.agents man on man.account = rep.parentagent
                 left join qt208.agents mas on mas.account = man.parentagent
        WHERE sd.set_id = set_id
          AND sd.sdata_validation_line_type = 'LIFELINE'
          AND DATE_FORMAT(sd.sdata_validation_activation_datetime, '%Y-%m-01') = sd.set_activity_month
        and sd.sdata_validation_fatal_error_code != 'X002'
        GROUP BY 1, 2, 3, 5;
    END LOOP;

    CLOSE cur;


    SELECT * FROM entouch_set_total_submissions;
end;

-----------------------------------------------------------------------------------------------------------------------------

  create
    definer = reportuser@`%` procedure sp_ops_entouch_calculate_response_active_rates()
begin
    -- Declare variables for looping
    DECLARE done INT DEFAULT 0;
    DECLARE activity_month DATE;
    DECLARE response_id INT;
    DECLARE cur CURSOR FOR
        SELECT r.id, r.response_activity_month
        FROM 497system.497response r
        WHERE r.response_revision = '0'
          AND r.response_activity_month >= CURDATE() - INTERVAL 18 MONTH
          AND r.response_schema = 'ENTOUCH';

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Delete existing data from the table before inserting new results
    DELETE FROM entouch_response_active_rates;

    -- Open the cursor
    OPEN cur;

    read_loop:
    LOOP
        FETCH cur INTO response_id, activity_month;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Insert the calculated response active rate for the current activity month
        INSERT INTO entouch_response_active_rates (response_id, response_activity_month, tribal_flag, state,
                                                   agent_class, master_fusion_id, master_name,
                                                   total_passed, total_submissions)
        SELECT response_id,
               ar.set_activity_month as set_activity_month,
               ar.tribal_flag        as tribal_flag,
               ar.state              as state,
               ar.agent_class        as agent_class,
               ar.master_fusion_id   as master_fusion_id,
               ar.master_name        as master_name,
               x.total_passed,
               ar.total_submissions
        from reporting.entouch_set_total_submissions ar
                 left join (SELECT DATE_FORMAT(rd.rdata_original_lifeline_activation_date, '%Y-%m-01') AS activation_month,
                                   rd.rdata_tribal_flag                                                as tribal_flag,
                                   rd.rdata_state                                                      as state,
                                   rep.agentclass                                                      as agent_class,
                                   ifnull(mas.account, ifnull(man.account, rep.account))               as master_fusion_id,
                                   ifnull(concat(mas.firstname, ' ', mas.lastname),
                                          ifnull(concat(man.firstname, ' ', man.lastname),
                                                 concat(rep.firstname, ' ', rep.lastname)))            as master_name,
                                   COUNT(1)                                                            AS total_passed
                            FROM 497entouch.497response_data rd
                                     left join qt208.customers c on c.account = rd.rdata_account_id and c.companyid = 6
                                     left join qt208.agents rep on rep.account = c.agentaccount
                                     left join qt208.agents man on man.account = rep.parentagent
                                     left join qt208.agents mas on mas.account = man.parentagent
                            WHERE rd.rdata_revision = '0'
                              AND rd.rdata_passed_edits = 'Y'
                              AND rd.rdata_file_type = 'UsacWireless2'
                              AND rd.response_activity_month = activity_month
                            group by 1, 2, 3, 5) x
                           on x.activation_month = ar.set_activity_month and x.tribal_flag = ar.tribal_flag and
                              x.state = ar.state and x.master_fusion_id = ar.master_fusion_id;

    END LOOP;

    -- Close the cursor
    CLOSE cur;

    -- View the results (optional)
    SELECT * FROM entouch_response_active_rates;

end;

