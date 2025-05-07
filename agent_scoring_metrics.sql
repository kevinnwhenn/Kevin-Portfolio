create
    definer = reportuser@`%` procedure sp_run_agent_scoring()
BEGIN

    SET @startDate = (SELECT DATE_SUB(CURDATE(), INTERVAL 8 DAY));
    SET @endDate = (SELECT DATE_SUB(CURDATE(), INTERVAL 1 DAY));

    SET @setIdAssist = (SELECT MAX(id)
                        FROM 497system.497set
                        WHERE set_schema = 'ASSIST'
                          AND set_type = 'REPORTING'
                          AND set_status = 'COMPLETED');

    SET @setIdEntouch = (SELECT MAX(id)
                         FROM 497system.497set
                         WHERE set_schema = 'ENTOUCH'
                           AND set_type = 'REPORTING'
                           AND set_status = 'COMPLETED');

# Pulls base agent list for the period
    INSERT INTO reporting.agent_scoring (period_start_date, period_end_date, etc, enrollment_rep_cgm_login,
                                         enrollment_rep_create_date, enrollment_rep_rad_id, enrollment_rep_fusion_id,
                                         enrollment_rep_fusion_status,
                                         enrollment_rep_name, manager_fusion_id, manager_name, master_fusion_id,
                                         master_name)
    SELECT DISTINCT @startDate,
                    @endDate,
                    CASE
                        WHEN c.companyid = 1 THEN 'ASSIST'
                        WHEN c.companyid = 6 THEN 'ENTOUCH'
                        END                                                  AS etc,
                    cou.cgm_agent_code                                       AS enrollment_rep_cgm_login,
                    rep.datecreated                                          AS enrollment_rep_create_date,
                    rep.representative_id                                    AS enrollment_rep_rad_id,
                    rep.account                                              AS enrollment_rep_fusion_id,
                    rep.status                                               AS enrollment_rep_fusion_status,
                    CONCAT(rep.firstname, ' ', rep.lastname)                 AS enrollment_rep_name,
                    IFNULL(man.account,
                           rep.account)                                      AS manager_fusion_id,
                    IFNULL(CONCAT(man.firstname, ' ', man.lastname),
                           CONCAT(rep.firstname, ' ', rep.lastname))         AS manager_name,
                    IFNULL(mas.account,
                           IFNULL(man.account,
                                  rep.account))                              AS master_fusion_id,
                    IFNULL(CONCAT(mas.firstname, ' ', mas.lastname),
                           IFNULL(CONCAT(man.firstname, ' ', man.lastname),
                                  CONCAT(rep.firstname, ' ', rep.lastname))) AS master_name
    FROM qt208.customers c
             LEFT JOIN qt208.agents rep ON rep.account = c.agentaccount
             LEFT JOIN qt208.agents man ON man.account = rep.parentagent
             LEFT JOIN qt208.agents mas ON mas.account = man.parentagent
             LEFT JOIN lifeline.cgm_orders_updated cou ON cou.vendor_account_id = c.account
    WHERE c.datecreated BETWEEN date_sub(@startDate, interval 90 day) AND @endDate
      AND c.agentaccount NOT IN (2446, 3181)
      AND cou.cgm_agent_code IS NOT NULL
    ORDER BY etc, master_fusion_id, manager_fusion_id, enrollment_rep_fusion_id;

# Sets total Lifeline enrollments during the period for Assist
    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT sd.sdata_agent_id, COUNT(1) AS total_enrollments
                   FROM 497assist.497set_data sd
                   WHERE sd.set_id = @setIdAssist
                     AND sd.sdata_validation_line_type = 'LIFELINE'
                     AND sd.sdata_validation_activation_datetime BETWEEN @startDate AND @endDate
                   GROUP BY sd.sdata_agent_id) y ON y.sdata_agent_id = x.enrollment_rep_fusion_id
    SET x.total_enrollments = y.total_enrollments
    WHERE x.etc = 'ASSIST'
      AND x.period_start_date = @startDate
      AND x.period_end_date = @endDate;

# Sets total Lifeline enrollments during the period for Entouch
    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT sd.sdata_agent_id, COUNT(1) AS total_enrollments
                   FROM 497entouch.497set_data sd
                   WHERE sd.set_id = @setIdEntouch
                     AND sd.sdata_validation_line_type = 'LIFELINE'
                     AND sd.sdata_validation_activation_datetime BETWEEN @startDate AND @endDate
                   GROUP BY sd.sdata_agent_id) y ON y.sdata_agent_id = x.enrollment_rep_fusion_id
    SET x.total_enrollments = y.total_enrollments
    WHERE x.etc = 'ENTOUCH'
      AND x.period_start_date = @startDate
      AND x.period_end_date = @endDate;

# Sets count of subscribers divided by the number of distinct addresses during the period for Assist
    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT sd.sdata_agent_id,
                          COUNT(1) / COUNT(DISTINCT sdata_residential_address1) AS address_to_sub_ratio
                   FROM 497assist.497set_data sd
                   WHERE sd.set_id = @setIdAssist
                     AND sd.sdata_validation_line_type = 'LIFELINE'
                     AND sd.sdata_validation_activation_datetime BETWEEN @startDate AND @endDate
                   GROUP BY sd.sdata_agent_id) y ON y.sdata_agent_id = x.enrollment_rep_fusion_id
    SET x.address_to_sub_ratio = y.address_to_sub_ratio
    WHERE x.etc = 'ASSIST'
      AND x.period_start_date = @startDate
      AND x.period_end_date = @endDate;

# Sets count of subscribers divided by the number of distinct addresses during the period for Entouch
    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT sd.sdata_agent_id,
                          COUNT(1) / COUNT(DISTINCT sdata_residential_address1) AS address_to_sub_ratio
                   FROM 497entouch.497set_data sd
                   WHERE sd.set_id = @setIdEntouch
                     AND sd.sdata_validation_line_type = 'LIFELINE'
                     AND sd.sdata_validation_activation_datetime BETWEEN @startDate AND @endDate
                   GROUP BY sd.sdata_agent_id) y ON y.sdata_agent_id = x.enrollment_rep_fusion_id
    SET x.address_to_sub_ratio = y.address_to_sub_ratio
    WHERE x.etc = 'ENTOUCH'
      AND x.period_start_date = @startDate
      AND x.period_end_date = @endDate;

    # set percentage of Assist CGM orders in 'Auditor Cancelled' or 'Cancel for Inactivity' status divide by total orders
# during the period.
    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT cgm_agent_code,
                          SUM(IF(last_status IN ('Auditor Cancelled', 'Cancel for Inactivity'), 1, 0)) /
                          COUNT(1) AS cancelled_order_pct
                   FROM lifeline.cgm_orders_updated
                   WHERE order_date BETWEEN @startDate AND @endDate
                     AND company = 'AST'
                   GROUP BY cgm_agent_code) y ON y.cgm_agent_code = x.enrollment_rep_cgm_login
    SET x.cancelled_order_pct = y.cancelled_order_pct
    WHERE x.etc = 'ASSIST'
      AND x.period_start_date = @startDate
      AND x.period_end_date = @endDate;

    # set percentage of Entouch CGM orders in 'Auditor Cancelled' or 'Cancel for Inactivity' status divide by total orders
# during the period.
    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT cgm_agent_code,
                          SUM(IF(last_status IN ('Auditor Cancelled', 'Cancel for Inactivity'), 1, 0)) /
                          COUNT(1) AS cancelled_order_pct
                   FROM lifeline.cgm_orders_updated
                   WHERE order_date BETWEEN @startDate AND @endDate
                     AND company = 'HHV'
                   GROUP BY cgm_agent_code) y ON y.cgm_agent_code = x.enrollment_rep_cgm_login
    SET x.cancelled_order_pct = y.cancelled_order_pct
    WHERE x.etc = 'ENTOUCH'
      AND x.period_start_date = @startDate
      AND x.period_end_date = @endDate;

    # set percentage of Assist subscribers enrolled by agent divided by the number of individual days agent was enrolling
# during the period.
    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT sd.sdata_agent_id,
                          COUNT(1) /
                          COUNT(DISTINCT
                                DATE_FORMAT(sd.sdata_validation_activation_datetime, '%Y-%m-%d')) AS enrollments_per_day_avg
                   FROM 497assist.497set_data sd
                   WHERE sd.set_id = @setIdAssist
                     AND sd.sdata_validation_line_type = 'LIFELINE'
                     AND sd.sdata_validation_activation_datetime BETWEEN @startDate AND @endDate
                   GROUP BY sd.sdata_agent_id) y ON y.sdata_agent_id = x.enrollment_rep_fusion_id
    SET x.enrollments_per_day_avg = y.enrollments_per_day_avg
    WHERE x.etc = 'ASSIST'
      AND x.period_start_date = @startDate
      AND x.period_end_date = @endDate;

    # set percentage of Entouch subscribers enrolled by agent divided by the number of individual days agent was enrolling
# during the period.
    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT sd.sdata_agent_id,
                          COUNT(1) /
                          COUNT(DISTINCT
                                DATE_FORMAT(sd.sdata_validation_activation_datetime, '%Y-%m-%d')) AS enrollments_per_day_avg
                   FROM 497entouch.497set_data sd
                   WHERE sd.set_id = @setIdEntouch
                     AND sd.sdata_validation_line_type = 'LIFELINE'
                     AND sd.sdata_validation_activation_datetime BETWEEN @startDate AND @endDate
                   GROUP BY sd.sdata_agent_id) y ON y.sdata_agent_id = x.enrollment_rep_fusion_id
    SET x.enrollments_per_day_avg = y.enrollments_per_day_avg
    WHERE x.etc = 'ENTOUCH'
      AND x.period_start_date = @startDate
      AND x.period_end_date = @endDate;

    # total number of Assist subscribers 90 days prior to the start date where the account status is equal to 'ACTIVE'
# divided by the total number of subscribers during that period.
    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT sd.sdata_agent_id,
                          SUM(IF(sd.sdata_customer_status = 'ACTIVE', 1, 0)) / COUNT(1) AS active_past_90day_pct
                   FROM 497assist.497set_data sd
                   WHERE sd.set_id = @setIdAssist
                     AND sd.sdata_validation_line_type = 'LIFELINE'
                     AND sd.sdata_validation_activation_datetime BETWEEN DATE_SUB(@endDate, INTERVAL 90 DAY) AND @endDate
                   GROUP BY sd.sdata_agent_id) y ON y.sdata_agent_id = x.enrollment_rep_fusion_id
    SET x.active_past_90day_pct = y.active_past_90day_pct
    WHERE x.etc = 'ASSIST'
      AND x.period_start_date = @startDate
      AND x.period_end_date = @endDate;

    # total number of Assist subscribers 90 days prior to the start date where the account status is equal to 'ACTIVE'
# divided by the total number of subscribers during that period.
    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT sd.sdata_agent_id,
                          SUM(IF(sd.sdata_customer_status = 'ACTIVE', 1, 0)) / COUNT(1) AS active_past_90day_pct
                   FROM 497entouch.497set_data sd
                   WHERE sd.set_id = @setIdEntouch
                     AND sd.sdata_validation_line_type = 'LIFELINE'
                     AND sd.sdata_validation_activation_datetime BETWEEN DATE_SUB(@endDate, INTERVAL 90 DAY) AND @endDate
                   GROUP BY sd.sdata_agent_id) y ON y.sdata_agent_id = x.enrollment_rep_fusion_id
    SET x.active_past_90day_pct = y.active_past_90day_pct
    WHERE x.etc = 'ENTOUCH'
      AND x.period_start_date = @startDate
      AND x.period_end_date = @endDate;


    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT sd.sdata_agent_id,
                          SUM(IF(DATEDIFF(IFNULL(GREATEST(cl.lastcallusagedate,
                                                          cl.lastdatausagedate,
                                                          cl.lastoutboundtextusagedate),
                                                 sd.sdata_validation_activation_datetime),
                                          sd.sdata_validation_activation_datetime) >= 2, 1, 0)) AS usage_past_day2_total
                   FROM 497assist.497set_data sd
                            LEFT JOIN qt208.customerlifeline cl ON cl.account = sd.sdata_account_id
                   WHERE sd.set_id = @setIdAssist
                     AND sd.sdata_validation_line_type = 'LIFELINE'
                     AND sd.sdata_validation_activation_datetime BETWEEN DATE_SUB(@startDate, INTERVAL 90 DAY) AND @startDate
                   GROUP BY sd.sdata_agent_id) y ON y.sdata_agent_id = x.enrollment_rep_fusion_id
    SET x.usage_past_day2_total = y.usage_past_day2_total
    WHERE x.etc = 'ASSIST'
      AND x.period_start_date = @startDate
      AND x.period_end_date = @endDate;

    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT sd.sdata_agent_id,
                          SUM(IF(DATEDIFF(IFNULL(GREATEST(cl.lastcallusagedate,
                                                          cl.lastdatausagedate,
                                                          cl.lastoutboundtextusagedate),
                                                 sd.sdata_validation_activation_datetime),
                                          sd.sdata_validation_activation_datetime) >= 2, 1, 0)) AS usage_past_day2_total
                   FROM 497entouch.497set_data sd
                            LEFT JOIN qt208.customerlifeline cl ON cl.account = sd.sdata_account_id
                   WHERE sd.set_id = @setIdEntouch
                     AND sd.sdata_validation_line_type = 'LIFELINE'
                     AND sd.sdata_validation_activation_datetime BETWEEN DATE_SUB(@startDate, INTERVAL 90 DAY) AND @startDate
                   GROUP BY sd.sdata_agent_id) y ON y.sdata_agent_id = x.enrollment_rep_fusion_id
    SET x.usage_past_day2_total = y.usage_past_day2_total
    WHERE x.etc = 'ENTOUCH'
      AND x.period_start_date = @startDate
      AND x.period_end_date = @endDate;

    # total accounts who have had usage after day 8 for assist
    update reporting.agent_scoring x
        left join (SELECT sd.sdata_agent_id,
                          SUM(IF(DATEDIFF(IFNULL(GREATEST(cl.lastcallusagedate,
                                                          cl.lastdatausagedate,
                                                          cl.lastoutboundtextusagedate),
                                                 sd.sdata_validation_activation_datetime),
                                          sd.sdata_validation_activation_datetime) >= 8, 1, 0)) AS usage_past_day8_total
                   FROM 497assist.497set_data sd
                            LEFT JOIN qt208.customerlifeline cl ON cl.account = sd.sdata_account_id
                   WHERE sd.set_id = @setIdAssist
                     AND sd.sdata_validation_line_type = 'LIFELINE'
                     AND sd.sdata_validation_activation_datetime BETWEEN DATE_SUB(@startDate, INTERVAL 90 DAY) AND @startDate
                   GROUP BY sd.sdata_agent_id) y on y.sdata_agent_id = x.enrollment_rep_fusion_id
    set x.usage_past_day8_total = y.usage_past_day8_total
    where x.etc = 'ASSIST'
      and x.period_start_date = @startDate
      and x.period_end_date = @endDate;

    # total accounts who have had usage after day 8 for entouch
    update reporting.agent_scoring x
        left join (SELECT sd.sdata_agent_id,
                          SUM(IF(DATEDIFF(IFNULL(GREATEST(cl.lastcallusagedate,
                                                          cl.lastdatausagedate,
                                                          cl.lastoutboundtextusagedate),
                                                 sd.sdata_validation_activation_datetime),
                                          sd.sdata_validation_activation_datetime) >= 8, 1, 0)) AS usage_past_day8_total
                   FROM 497entouch.497set_data sd
                            LEFT JOIN qt208.customerlifeline cl ON cl.account = sd.sdata_account_id
                   WHERE sd.set_id = @setIdEntouch
                     AND sd.sdata_validation_line_type = 'LIFELINE'
                     AND sd.sdata_validation_activation_datetime BETWEEN DATE_SUB(@startDate, INTERVAL 90 DAY) AND @startDate
                   GROUP BY sd.sdata_agent_id) y on y.sdata_agent_id = x.enrollment_rep_fusion_id
    set x.usage_past_day8_total = y.usage_past_day8_total
    where x.etc = 'ENTOUCH'
      and x.period_start_date = @startDate
      and x.period_end_date = @endDate;

    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT sd.sdata_agent_id, COUNT(1) AS enroll_past_90_total
                   FROM 497assist.497set_data sd
                   WHERE sd.set_id = @setIdAssist
                     AND sd.sdata_validation_line_type = 'LIFELINE'
                     AND sd.sdata_validation_activation_datetime BETWEEN DATE_SUB(@startDate, INTERVAL 90 DAY) AND @startDate
                   GROUP BY sd.sdata_agent_id) y ON y.sdata_agent_id = x.enrollment_rep_fusion_id
    SET x.enroll_past_90day_total = y.enroll_past_90_total
    WHERE x.etc = 'ASSIST'
      AND x.period_start_date = @startDate
      AND x.period_end_date = @endDate;

    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT sd.sdata_agent_id, COUNT(1) AS enroll_past_90_total
                   FROM 497entouch.497set_data sd
                   WHERE sd.set_id = @setIdEntouch
                     AND sd.sdata_validation_line_type = 'LIFELINE'
                     AND sd.sdata_validation_activation_datetime BETWEEN DATE_SUB(@startDate, INTERVAL 90 DAY) AND @startDate
                   GROUP BY sd.sdata_agent_id) y ON y.sdata_agent_id = x.enrollment_rep_fusion_id
    SET x.enroll_past_90day_total = y.enroll_past_90_total
    WHERE x.etc = 'ENTOUCH'
      AND x.period_start_date = @startDate
      AND x.period_end_date = @endDate;

    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT agent_code,
                          SUM(IF(status = 'DMD Failure', 1, 0))            AS total_dmd_failures,
                          SUM(IF(status = 'DMD Failure', 1, 0)) / COUNT(1) AS dmd_failure_order_pct
                   FROM lifeline.cgm_orders
                   WHERE order_date BETWEEN @startDate AND @endDate
                   GROUP BY agent_code) y ON y.agent_code = x.enrollment_rep_cgm_login
    SET x.total_dmd_failures    = y.total_dmd_failures,
        x.dmd_failure_order_pct = y.dmd_failure_order_pct
    WHERE x.period_start_date = @startDate
      AND x.period_end_date = @endDate;

    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT agent_code,
                          SUM(
                                  CASE
                                      WHEN state = 'CA' AND
                                           DATE_FORMAT(CONVERT_TZ(order_date_time, 'UTC', 'America/Chicago'), '%w') =
                                           0 AND
                                           (TIME(CONVERT_TZ(order_date_time, 'UTC', 'America/Chicago')) >= '21:00:00' OR
                                            TIME(CONVERT_TZ(order_date_time, 'UTC', 'America/Chicago')) < '10:00:00')
                                          THEN 1
                                      WHEN state = 'CA' AND
                                           DATE_FORMAT(CONVERT_TZ(order_date_time, 'UTC', 'America/Chicago'), '%w') !=
                                           0 AND
                                           (TIME(CONVERT_TZ(order_date_time, 'UTC', 'America/Chicago')) >= '23:00:00' OR
                                            TIME(CONVERT_TZ(order_date_time, 'UTC', 'America/Chicago')) < '08:00:00')
                                          THEN 1
                                      WHEN state != 'CA' AND
                                           (TIME(CONVERT_TZ(order_date_time, 'UTC', 'America/Chicago')) >= '20:00:00' OR
                                            TIME(CONVERT_TZ(order_date_time, 'UTC', 'America/Chicago')) < '08:00:00')
                                          THEN 1
                                      ELSE 0
                                      END) AS after_hours_orders
                   FROM lifeline.cgm_orders
                   WHERE order_date BETWEEN @startDate
                       AND @endDate
                     AND agent_code NOT IN ('astselfenroll', 'hhvEcommBQ')
                   GROUP BY agent_code) y ON y.agent_code = x.enrollment_rep_cgm_login
    SET x.after_hours_orders = y.after_hours_orders
    WHERE x.period_start_date = @startDate
      AND x.period_end_date = @endDate;

# 30 day from start date transfer out percentage for assist
    update reporting.agent_scoring x
        left join (select sd.sdata_agent_id,
                          sum(if(sd.sdata_validation_lifeline_status in
                                 ('SETGEN_BROADBAND_TRANSFER', 'SETGEN_NLAD_TRANSFER', 'SETGEN_XEROX_TRANSFER'), 1,
                                 0)) /
                          count(1) as 30_day_transfer_out_pct
                   from 497assist.497set_data sd
                   where sd.set_id = @setIdAssist
                     and sd.sdata_validation_activation_datetime between date_sub(@startDate, interval 30 day) and @startDate
                   group by sd.sdata_agent_id) y on y.sdata_agent_id = x.enrollment_rep_fusion_id
    set x.30_day_transfer_out_pct = y.30_day_transfer_out_pct
    where x.etc = 'ASSIST'
      and x.period_start_date = @startDate
      and x.period_end_date = @endDate;

    # 30 day from start date transfer out percentage for entouch
    update reporting.agent_scoring x
        left join (select sd.sdata_agent_id,
                          sum(if(sd.sdata_validation_lifeline_status in
                                 ('SETGEN_BROADBAND_TRANSFER', 'SETGEN_NLAD_TRANSFER', 'SETGEN_XEROX_TRANSFER'), 1,
                                 0)) /
                          count(1) as 30_day_transfer_out_pct
                   from 497entouch.497set_data sd
                   where sd.set_id = @setIdEntouch
                     and sd.sdata_validation_activation_datetime between date_sub(@startDate, interval 30 day) and @startDate
                   group by sd.sdata_agent_id) y on y.sdata_agent_id = x.enrollment_rep_fusion_id
    set x.30_day_transfer_out_pct = y.30_day_transfer_out_pct
    where x.etc = 'ENTOUCH'
      and x.period_start_date = @startDate
      and x.period_end_date = @endDate;

    # 60 day from start date transfer out percentage for assist
    update reporting.agent_scoring x
        left join (select sd.sdata_agent_id,
                          sum(if(sd.sdata_validation_lifeline_status in
                                 ('SETGEN_BROADBAND_TRANSFER', 'SETGEN_NLAD_TRANSFER', 'SETGEN_XEROX_TRANSFER'), 1,
                                 0)) /
                          count(1) as 60_day_transfer_out_pct
                   from 497assist.497set_data sd
                   where sd.set_id = @setIdAssist
                     and sd.sdata_validation_activation_datetime between date_sub(@startDate, interval 60 day) and @startDate
                   group by sd.sdata_agent_id) y on y.sdata_agent_id = x.enrollment_rep_fusion_id
    set x.60_day_transfer_out_pct = y.60_day_transfer_out_pct
    where x.etc = 'ASSIST'
      and x.period_start_date = @startDate
      and x.period_end_date = @endDate;

    # 60 day from start date transfer out percentage for entouch
    update reporting.agent_scoring x
        left join (select sd.sdata_agent_id,
                          sum(if(sd.sdata_validation_lifeline_status in
                                 ('SETGEN_BROADBAND_TRANSFER', 'SETGEN_NLAD_TRANSFER', 'SETGEN_XEROX_TRANSFER'), 1,
                                 0)) /
                          count(1) as 60_day_transfer_out_pct
                   from 497entouch.497set_data sd
                   where sd.set_id = @setIdEntouch
                     and sd.sdata_validation_activation_datetime between date_sub(@startDate, interval 60 day) and @startDate
                   group by sd.sdata_agent_id) y on y.sdata_agent_id = x.enrollment_rep_fusion_id
    set x.60_day_transfer_out_pct = y.60_day_transfer_out_pct
    where x.etc = 'ENTOUCH'
      and x.period_start_date = @startDate
      and x.period_end_date = @endDate;

    UPDATE reporting.agent_scoring
    SET total_enrollments = 0
    WHERE period_start_date = @startDate
      AND period_end_date = @endDate
      AND total_enrollments IS NULL;

    UPDATE reporting.agent_scoring
    SET address_to_sub_ratio = 0
    WHERE period_start_date = @startDate
      AND period_end_date = @endDate
      AND address_to_sub_ratio IS NULL;

    UPDATE reporting.agent_scoring
    SET cancelled_order_pct = 0
    WHERE period_start_date = @startDate
      AND period_end_date = @endDate
      AND cancelled_order_pct IS NULL;

    UPDATE reporting.agent_scoring
    SET enrollments_per_day_avg = 0
    WHERE period_start_date = @startDate
      AND period_end_date = @endDate
      AND enrollments_per_day_avg IS NULL;

    UPDATE reporting.agent_scoring
    SET active_past_90day_pct = 0
    WHERE period_start_date = @startDate
      AND period_end_date = @endDate
      AND active_past_90day_pct IS NULL;

    UPDATE reporting.agent_scoring
    SET usage_past_day2_total = 0
    WHERE period_start_date = @startDate
      AND period_end_date = @endDate
      AND usage_past_day2_total IS NULL;

    UPDATE reporting.agent_scoring
    SET enroll_past_90day_total = 0
    WHERE period_start_date = @startDate
      AND period_end_date = @endDate
      AND enroll_past_90day_total IS NULL;

    UPDATE reporting.agent_scoring
    SET usage_past_day2_past_90day_pct = (usage_past_day2_total / enroll_past_90day_total)
    WHERE period_start_date = @startDate
      AND period_end_date = @endDate;

    update reporting.agent_scoring
    set usage_past_day8_past_90day_pct = (usage_past_day8_total / enroll_past_90day_total)
    where period_start_date = @startDate
      and period_end_date = @endDate;


    UPDATE reporting.agent_scoring x
        LEFT JOIN (SELECT x.cgm_agent_code,
                          SUM(IF(order_attempts > 5, 1, 0)) AS attempts_abv_velocity
                   FROM (SELECT o.agent_code AS cgm_agent_code,
                                COUNT(*)     AS order_attempts
                         FROM lifeline.cgm_orders o
                         WHERE o.order_date BETWEEN @startDate AND @endDate
                         GROUP BY DATE_FORMAT(o.order_date_time, '%Y-%m-%d %H:'), FLOOR(MINUTE(o.order_date_time) / 10),
                                  o.agent) x
                   GROUP BY x.cgm_agent_code) y ON y.cgm_agent_code = x.enrollment_rep_cgm_login
    SET x.attempts_above_velocity = y.attempts_abv_velocity
    WHERE x.period_start_date = @startDate
      AND x.period_end_date = @endDate;

    UPDATE reporting.agent_scoring
    SET after_hours_orders = 0
    WHERE after_hours_orders IS NULL
      AND period_start_date = @startDate
      AND period_end_date = @endDate;

    update reporting.agent_scoring
    set usage_past_day8_total = 0
    where usage_past_day8_total is null
      and period_start_date = @startDate
      and period_end_date = @endDate;

    update reporting.agent_scoring
    set 30_day_transfer_out_pct = 0
    where 30_day_transfer_out_pct is null
      and period_start_date = @startDate
      and period_end_date = @endDate;

    update reporting.agent_scoring
    set 60_day_transfer_out_pct = 0
    where 60_day_transfer_out_pct is null
      and period_start_date = @startDate
      and period_end_date = @endDate;

    update reporting.agent_scoring x
        left join qt208.agents rep on rep.account = x.enrollment_rep_fusion_id
    set x.enrollment_rep_fusion_status = rep.Status
    where period_start_date = @startDate
      and period_end_date = @endDate;

    UPDATE reporting.agent_scoring
    SET run_datetime = NOW()
    WHERE period_start_date = @startDate
      AND period_end_date = @endDate;

END;

