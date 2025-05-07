create definer = reportuser@`%` view ops_assist_enrollment_versus_loa as
select ifnull(`mas`.`account`, ifnull(`man`.`account`, `rep`.`account`))                                                  AS `master_fusion_id`,
       ifnull(concat(`mas`.`firstname`, ' ', `mas`.`lastname`), ifnull(concat(`man`.`firstname`, ' ', `man`.`lastname`),
                                                                       concat(`rep`.`firstname`, ' ', `rep`.`lastname`))) AS `master_name`,
       ifnull(`man`.`account`, `rep`.`account`)                                                                           AS `manager_fusion_id`,
       ifnull(concat(`man`.`firstname`, ' ', `man`.`lastname`),
              concat(`rep`.`firstname`, ' ', `rep`.`lastname`))                                                           AS `manager_name`,
       `sdrv`.`sdata_agent_id`                                                                                            AS `enrollment_rep_fusion_id`,
       concat(`rep`.`firstname`, ' ', `rep`.`lastname`)                                                                   AS `enrollment_rep_name`,
       `sdrv`.`sdata_agent_class`                                                                                         AS `agent_class`,
       `rep`.`Status`                                                                                                     AS `rep_status`,
       ifnull(`man`.`Status`, `rep`.`Status`)                                                                             AS `manager_status`,
       ifnull(`mas`.`Status`, ifnull(`man`.`Status`, `rep`.`Status`))                                                     AS `master_status`,
       date_format(`sdrv`.`sdata_validation_activation_datetime`,
                   '%Y-%m-01')                                                                                            AS `activation_month`,
       to_days(ifnull(if(`sdrv`.`sdata_cancel_date` = '1969-12-31', `sdrv`.`sdata_validation_denial_datetime`,
                         `sdrv`.`sdata_cancel_date`), curdate())) -
       to_days(date_format(`sdrv`.`sdata_validation_activation_datetime`,
                           '%Y-%m-%d'))                                                                                   AS `loa`,
       (to_days(ifnull(if(`sdrv`.`sdata_cancel_date` = '1969-12-31', `sdrv`.`sdata_validation_denial_datetime`,
                          `sdrv`.`sdata_cancel_date`), curdate())) -
        to_days(date_format(`sdrv`.`sdata_validation_activation_datetime`, '%Y-%m-%d'))) / (to_days(curdate()) -
                                                                                            to_days(date_format(
                                                                                                    `sdrv`.`sdata_validation_activation_datetime`,
                                                                                                    '%Y-%m-%d')))         AS `normalized_loa`,
       `sdrv`.`sdata_tribal_flag`                                                                                         AS `tribal_flag`,
       `sdrv`.`sdata_residential_city`                                                                                    AS `city`,
       `sdrv`.`sdata_state`                                                                                               AS `state`,
       `sdrv`.`sdata_residential_zip`                                                                                     AS `postal_code`,
       `sdrv`.`sdata_account_id`                                                                                          AS `account_id`,
       `sdrv`.`sdata_validation_fatal_error_code`                                                                         AS `error_code`,
       `it`.`description`                                                                                                 AS `inventory_type`,
       `ima`.`manufacturename`                                                                                            AS `iventory_manufacturer_name`,
       `imo`.`modelname`                                                                                                  AS `inventory_model_name`,
       ifnull(`co`.`dmd_override`, 'N')                                                                                   AS `dmd_override_flag`
from ((((((((((`497assist`.`497set_data_reporting_view` `sdrv` left join `qt208`.`agents` `rep`
               on (`rep`.`account` = `sdrv`.`sdata_agent_id`)) left join `qt208`.`agents` `man`
              on (`man`.`account` = `rep`.`parentagent`)) left join `qt208`.`agents` `mas`
             on (`mas`.`account` = `man`.`parentagent`)) left join `qt208`.`telephones_fixed` `tf`
            on (`tf`.`account` = `sdrv`.`sdata_account_id` and
                `tf`.`id` = `sdrv`.`sdata_ld_plan_id`)) left join `qt208`.`telephonecellular` `tc`
           on (`tc`.`telephoneid` = `tf`.`id`)) left join `qt208`.`inventoryunit` `iu`
          on (`iu`.`imei` = `tc`.`imei`)) left join `qt208`.`inventorytype` `it`
         on (`it`.`id` = `iu`.`inventorytypeid`)) left join `qt208`.`inventorymodel` `imo`
        on (`imo`.`id` = `iu`.`inventorymodelid`)) left join `qt208`.`inventorymanufacture` `ima`
       on (`ima`.`id` = `imo`.`manufactureid`)) left join `lifeline`.`cgm_orders` `co`
      on (`co`.`vendor_account_id` = `sdrv`.`sdata_account_id`))
where `sdrv`.`sdata_agent_id` <> 2446
  and `sdrv`.`sdata_validation_activation_datetime` >= '2023-07-01'
  and `sdrv`.`sdata_validation_line_type` = 'LIFELINE'
having `loa` > 0;

