--------------------------------------------------------
--  File created - Monday-November-26-2018   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package XX_ERP_INV_ATTACH_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "AITKEN"."XX_ERP_INV_ATTACH_PKG" AS 
    
    function xx_bi_output_f (p_username varchar2,p_password varchar2,p_parameter varchar2) return XMLType;
    function get_tag_value(p_xml varchar2, p_open_tag varchar2, p_close_tag varchar2) return varchar2;
    procedure XX_GET_AP_INV_DETAILS(x_bar_code in varchar2, x_user_key1 out varchar2, x_user_key2 out varchar2, x_user_key3 out varchar2, x_user_key4 out varchar2, x_user_key5 out varchar2, is_invoiced out varchar2);
    procedure XX_BASE64_ENCODE_FILE(P_DIR varchar2, P_INPUT_FILENAME varchar2, P_ENCODED_FILENAME varchar2);
    function XX_BASE64_DECODE_FILE_F (P_DIR varchar2, P_INPUT_FILENAME varchar2) return Clob;
    function xx_erp_attach_doc_p(p_password varchar2,p_file varchar2, p_user_key1 varchar2, p_user_key2 varchar2, p_user_key3 varchar2, p_user_key4 varchar2, p_user_key5 varchar2) return varchar2;
    procedure XX_MOVE_TEMP_FILES(P_SOURCE_FILE_DIR varchar2, P_SOURCE_FILE_NAME varchar2, P_TARGET_FILE_DIR varchar2, P_TARGET_FILE_NAME varchar2);
    procedure XX_EXECUTE_ATTACH(P_DIR varchar2, P_INPUT_FILENAME varchar2, P_INPUT_FILE_NAME varchar2, P_BAR_CODE varchar2, P_INPUT_FN_ENCRIPT varchar2, p_password varchar2);
    procedure XX_EXECUTE;
    procedure create_schedule;
    procedure XX_DROP_JOB_SCHEDULE;
    
END XX_ERP_INV_ATTACH_PKG;

/
