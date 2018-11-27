--------------------------------------------------------
--  File created - Monday-November-26-2018   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body XX_ERP_INV_ATTACH_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "AITKEN"."XX_ERP_INV_ATTACH_PKG" AS
    
    function xx_bi_output_f (
                                p_username varchar2,
                                p_password varchar2,
                                p_parameter varchar2
                            ) return XMLType as
    env  clob; --     VARCHAR2(32767);
    l_http_request   UTL_HTTP.req;
    l_http_response  UTL_HTTP.resp;
    l_resp_xml       XMLType;
    l_result_value clob; --varchar2(32767);
    l_ns_map         varchar2(2000) ;
    x_clob             CLOB;
    l_buffer     VARCHAR2(32767);
    l_chunkStart NUMBER := 1;
    l_chunkData VARCHAR2(32000);
    l_chunkLength NUMBER := 32000;
    l_start_position number := 1;
    l_position number := 1;
  BEGIN
--    generate_envelope(req, env);
--<?xml version="1.0" encoding="utf-8"?>
    env:='<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:pub="http://xmlns.oracle.com/oxp/service/PublicReportService">
   <soap:Header/>
   <soap:Body>
      <pub:runReport>
         <pub:reportRequest>
                     <pub:parameterNameValues>
               <!--Zero or more repetitions:-->
               <pub:item>
                  <pub:name>P_BAR_CODE</pub:name>
                  <pub:values>
                     <!--Zero or more repetitions:-->
                     <pub:item>'||p_parameter||'</pub:item>
                  </pub:values>
               </pub:item>
            </pub:parameterNameValues>         
            <pub:reportAbsolutePath>/Custom/fahad/XX_ERP_ATTACH.xdo</pub:reportAbsolutePath>
            <pub:sizeOfDataChunkDownload>10000</pub:sizeOfDataChunkDownload>
         </pub:reportRequest>
         <pub:appParams/>
         <userid>'||p_username||'</userid>
         <password>'||p_password||'</password>
      </pub:runReport>
   </soap:Body>
</soap:Envelope>';
    l_ns_map := l_ns_map ||'xmlns:ns2="http://xmlns.oracle.com/oxp/service/PublicReportService"';
  --UTL_HTTP.set_wallet('file:/u01/app/oracle/product/12.1.0/dbhome_1/owm/wallets/oracle', 'passwd');
     UTL_HTTP.set_wallet('file:/home/oracle/wallet', null);
    l_http_request := utl_http.begin_request('https://ehpc-test.fa.em2.oraclecloud.com/xmlpserver/services/PublicReportWSSService', 'POST','HTTP/1.1');
    UTL_HTTP.set_authentication(l_http_request, 'lhettairachchi2@kpmg.com', p_password);
    UTL_HTTP.set_header(l_http_request, 'Content-Type', 'application/soap+xml;charset="UTF-8"');
    UTL_HTTP.set_header(l_http_request, 'Content-Length', LENGTH(env));
    
     --l_chunkLength := dbms_lob.getlength(convert(env,'UTF8'));
     --l_chunkLength := 32000;
     env := convert(env,'UTF8');
     
    UTL_HTTP.set_header(l_http_request, 'Transfer-Encoding', 'chunked');
   -- utl_http.set_header(l_http_request, 'SOAPAction','');
 
    LOOP
      l_chunkData := NULL;
      l_chunkData := SUBSTR(env, l_chunkStart, l_chunkLength);
      UTL_HTTP.write_text(l_http_request, l_chunkData);
      IF (LENGTH(l_chunkData) < l_chunkLength) 
        THEN EXIT; 
      END IF;
      l_chunkStart := l_chunkStart + l_chunkLength;
    END LOOP;
        
     --  Get the response and process it
     l_http_response := UTL_HTTP.get_response(l_http_request);
    -- Create a CLOB to hold web service response
    dbms_lob.createtemporary(x_clob, FALSE );
    dbms_lob.open(x_clob, dbms_lob.lob_readwrite);
    
--    DBMS_OUTPUT.PUT_LINE('HTTP ' ||l_http_response.status_code);
    
    begin
      loop
        -- Copy the web service response body in a buffer string variable l_buffer
        utl_http.read_text(l_http_response, l_buffer);
      -- Append data from l_buffer to CLOB variable
        dbms_lob.writeappend(x_clob
                          , length(l_buffer)
                          , l_buffer);
      end loop;  
      exception
        when UTL_HTTP.end_of_body then
          UTL_HTTP.end_response(l_http_response);
    end;
  l_start_position := instr(x_clob,'env:Envelope',1,1)-1;
  l_position := instr(x_clob,'env:Envelope',l_start_position,2);
        
    if l_http_response.status_code = 200 THEN
        
      l_resp_xml := XMLType.createXML(x_clob);
  
   SELECT  extractValue(l_resp_xml, 
    '//ns2:reportBytes','xmlns:ns2="http://xmlns.oracle.com/oxp/service/PublicReportService"')
    INTO l_result_value
    FROM dual;
      
      commit;
    
    end if;
    
    select xmltype(UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_DECODE(UTL_RAW.CAST_TO_RAW(l_result_value)))) into l_resp_xml from dual;
    
    --dbms_output.put_line('Result = '||l_resp_xml.getStringVal());
    dbms_lob.freetemporary(x_clob);
    return l_resp_xml;
    exception
      when others then      
       UTL_HTTP.end_response(l_http_response);
       return null;
      -- dbms_output.put_line ('Error- ' ||sqlerrm);
  END;
  
    function get_tag_value(p_xml varchar2, p_open_tag varchar2, p_close_tag varchar2)
    return varchar2
    as
        tag_value varchar2(240);
       
    begin
        select substr(p_xml, INSTR(p_xml, p_open_tag) + LENGTH(p_open_tag), INSTR(p_xml, p_close_tag) - INSTR(p_xml, p_open_tag) - LENGTH(p_open_tag)) tag_value
        into tag_value
        from dual;
        
        return tag_value;
    
    end;

  procedure XX_GET_AP_INV_DETAILS(x_bar_code in varchar2, x_user_key1 out varchar2, x_user_key2 out varchar2, x_user_key3 out varchar2, x_user_key4 out varchar2, x_user_key5 out varchar2, is_invoiced out varchar2)
  as
    l_inv_ref   varchar2(240);
    aa          varchar2(20000);
    l_tag1_o varchar2(50)   := '<P_BAR_CODE>';--invoice reference
    l_tag1_c varchar2(50)   := '</P_BAR_CODE>';--invoice reference
    l_tag2_o varchar2(50)   := '<USERKEYA>';--Business Unit
    l_tag2_c varchar2(50)   := '</USERKEYA>';--Business Unit
    l_tag3_o varchar2(50)   := '<USERKEYB>';--Invoice Numeber
    l_tag3_c varchar2(50)   := '</USERKEYB>';--Invoice Numeber
    l_tag4_o varchar2(50)   := '<USERKEYC>';--Invoice Suppler Number
    l_tag4_c varchar2(50)   := '</USERKEYC>';--Invoice Suppler Number
    l_tag5_o varchar2(50)   := '<ENTITYNAME>';
    l_tag5_c varchar2(50)   := '</ENTITYNAME>';
    l_tag6_o varchar2(50)   := '<CATEGORYNAME>';
    l_tag6_c varchar2(50)   := '</CATEGORYNAME>';
    l_tag7_o varchar2(50)   := '<ERROR_MSG>';
    l_tag7_c varchar2(50)   := '</ERROR_MSG>';
  
  
  begin
            --assign the barcode as the invoice reference
            l_inv_ref := x_bar_code;

            begin
            --when there is no files
            IF l_inv_ref is not null
            THEN
              --inquire invoice information based on the barcode
              aa := xx_bi_output_f ('lhettairachchi2@kpmg.com','Lakshani@12345',l_inv_ref).getStringVal;
              
              is_invoiced:= null;
              --check for availability of inquired invoiced information
              IF get_tag_value(p_xml => aa, p_open_tag => l_tag7_o, p_close_tag => l_tag7_c) != 'Y'
                then
                is_invoiced := null;
              ELSE
                is_invoiced := 'INVOICED';
              END IF;
            END IF;
            
            end;
            --if bar code attached is invoiced extract the response payload
            if is_invoiced = 'INVOICED'
            then
                IF l_inv_ref = get_tag_value(p_xml => aa, p_open_tag => l_tag1_o, p_close_tag => l_tag1_c) and get_tag_value(p_xml => aa, p_open_tag => l_tag7_o, p_close_tag => l_tag7_c) = 'Y'
                THEN
                    x_user_key1 := get_tag_value(p_xml => aa, p_open_tag => l_tag2_o, p_close_tag => l_tag2_c);
                    x_user_key2 := get_tag_value(p_xml => aa, p_open_tag => l_tag3_o, p_close_tag => l_tag3_c);
                    x_user_key3 := get_tag_value(p_xml => aa, p_open_tag => l_tag4_o, p_close_tag => l_tag4_c);
                    x_user_key4 := get_tag_value(p_xml => aa, p_open_tag => l_tag5_o, p_close_tag => l_tag5_c);
                    x_user_key5 := get_tag_value(p_xml => aa, p_open_tag => l_tag6_o, p_close_tag => l_tag6_c);
                END IF;
            end if;
  end;

  procedure XX_BASE64_ENCODE_FILE( P_DIR varchar2, P_INPUT_FILENAME varchar2, P_ENCODED_FILENAME varchar2) 
  AS
   WF_INPUT       utl_file.file_type;
   WF_ENCODE      utl_file.file_type;
   WB_EXISTS      boolean;
   WN_FILE_LENGTH number;
   WN_BLOCKSIZE   number;
   WN_OFFSET      number := 0;
   WR_BUFFER      raw(255);
begin
   -- Use fgetattr to get thse file length.
   utl_file.fgetattr(
      P_DIR,
      P_INPUT_FILENAME,
      WB_EXISTS,
      WN_FILE_LENGTH,
      WN_BLOCKSIZE
   );
   -- Open both files in binary mode
   WF_INPUT := utl_file.fopen( P_DIR,P_INPUT_FILENAME,'rb',255);
   WF_ENCODE := utl_file.fopen( P_DIR,P_ENCODED_FILENAME,'wb',255);
   -- Process the input file in 57 byte chunks since this results
   -- in an output of one 76 byte record.
   while( WN_OFFSET <= WN_FILE_LENGTH) loop
      utl_file.get_raw( WF_INPUT, WR_BUFFER, 57);
      utl_file.put_raw( WF_ENCODE, utl_encode.base64_encode(WR_BUFFER));
      WN_OFFSET := WN_OFFSET + 57;
   end loop;
   -- Close files
   utl_file.fclose( WF_INPUT);
   utl_file.fclose( WF_ENCODE);
exception
   when others then
      utl_file.fclose( WF_INPUT);
      utl_file.fclose( WF_ENCODE);
      raise;
  END XX_BASE64_ENCODE_FILE;

  function XX_BASE64_DECODE_FILE_F ( P_DIR varchar2, P_INPUT_FILENAME varchar2) return Clob 
  AS

    WF_INPUT      utl_file.file_type;
   WB_EOF         boolean := false;
   WR_BUFFER      varchar2(255);
   x_clob Clob;
begin
   -- Open the input file in text mode (since Base64 encoded data uses
   -- ascii characters).
   -- Open the output file in binary.
   WF_INPUT := utl_file.fopen( P_DIR,P_INPUT_FILENAME,'r');

    -- Create a CLOB to hold web service response
   -- Loop though all records in the file, decoding the data and 
   -- writing it out to an output file, here you could easily write
   -- to a BLOB instead.
   while( WB_EOF = false) loop
      begin
         utl_file.get_line( WF_INPUT, WR_BUFFER);
        x_clob := x_clob || to_clob(WR_BUFFER);      
      exception
       --  No data found is raised when the end of the file is reached
         when no_data_found then
         WB_EOF := TRUE;
      end;
   end loop;
   utl_file.fclose( WF_INPUT);
          Return x_clob;
exception
   when others then
      utl_file.fclose( WF_INPUT);
      return NULL;
      --raise;
  END XX_BASE64_DECODE_FILE_F;

  function xx_erp_attach_doc_p(p_password varchar2,p_file varchar2, p_user_key1 varchar2, p_user_key2 varchar2, p_user_key3 varchar2, p_user_key4 varchar2, p_user_key5 varchar2)
  return varchar2
  AS
    env      clob; -- VARCHAR2(32767);
    l_result         VARCHAR2(32767) := null;
    l_http_request   UTL_HTTP.req;
    l_http_response  UTL_HTTP.resp;
    l_counter        PLS_INTEGER;
    l_length         PLS_INTEGER;
    l_resp_xml       XMLType;
    l_result_value varchar2(100);
    l_ns_map         varchar2(2000) ;
    x_clob             CLOB;
    l_buffer     VARCHAR2(32767);     
    l_chunkStart NUMBER := 1;
    l_chunkData VARCHAR2(32000);
    l_chunkLength NUMBER := 32000;
    l_start_position number := 1;
    l_position number := 1;
    l_attachment_clob clob;
    l_upload_file varchar2(100) := p_file;
    
    --Invoice Keys
        l_user_key1 varchar2(240);
        l_user_key2 varchar2(240);
        l_user_key3 varchar2(240);
        l_user_key4 varchar2(240);
        l_user_key5 varchar2(240);        
    
  BEGIN
    begin
        l_user_key1 := p_user_key1;--ASPLC_BU
        l_user_key2 := p_user_key2;--B1
        l_user_key3 := p_user_key3;--10004
        l_user_key4 := p_user_key4;--B1
        l_user_key5 := p_user_key5;--10004
    
 
   l_attachment_clob := XX_BASE64_DECODE_FILE_F ('AITKEN_IMG','APINV_ENCODE_TMP.txt');
   
   -- not working l_attachment_clob := XX_TMP_BASE64_ENCODE_FILE ('MYDIR',p_file , 'cc.txt');
--    generate_envelope(req, env);
--<?xml version="1.0" encoding="utf-8"?>
    env:='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types/" xmlns:erp="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/">
   <soapenv:Header/>
   <soapenv:Body>
      <typ:uploadAttachment>
         <typ:entityName>'||l_user_key4||'</typ:entityName>
         <typ:categoryName>'||l_user_key5||'</typ:categoryName>
         <typ:allowDuplicate>Yes</typ:allowDuplicate>
         <!--Zero or more repetitions:-->
         <typ:attachmentRows>
            <!--Optional:-->
            <erp:UserKeyA>'||l_user_key1||'</erp:UserKeyA>
            <!--Optional:-->
            <erp:UserKeyB>'||l_user_key2||'</erp:UserKeyB>
            <!--Optional:-->
            <erp:UserKeyC>'||l_user_key3||'</erp:UserKeyC>
            <!--Optional:-->
            <erp:UserKeyD>#NULL</erp:UserKeyD>
            <!--Optional:-->
            <erp:UserKeyE>#NULL</erp:UserKeyE>
            <!--Optional:-->
            <erp:AttachmentType>FILE</erp:AttachmentType>
            <!--Optional:-->
            <erp:Title>'||l_upload_file||'</erp:Title>
            <!--Optional:-->
            <erp:Content>'||l_attachment_clob||'</erp:Content>
         </typ:attachmentRows>
      </typ:uploadAttachment>
   </soapenv:Body>
</soapenv:Envelope>';
    l_ns_map := l_ns_map ||'xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsa="http://www.w3.org/2005/08/addressing"';
  --UTL_HTTP.set_wallet('file:/u01/app/oracle/product/12.1.0/dbhome_1/owm/wallets/oracle', 'passwd');
    dbms_output.put_line ('payload 1 - ');
    UTL_HTTP.set_wallet('file:/home/oracle/wallet', null);
    dbms_output.put_line ('payload 2 - ');
    l_http_request := utl_http.begin_request('https://ehpc-test.fa.em2.oraclecloud.com/fscmService/ErpObjectAttachmentService', 'POST','HTTP/1.1');
    dbms_output.put_line ('payload 3 - ');
    UTL_HTTP.set_authentication(l_http_request, 'lhettairachchi2@kpmg.com', p_password);
    dbms_output.put_line ('payload 4 - ');
    UTL_HTTP.set_header(l_http_request, 'Content-Type', 'text/xml;charset="UTF-8"');
    dbms_output.put_line ('payload 5 - ');
    UTL_HTTP.set_header(l_http_request, 'Content-Length', LENGTH(env));
     --l_chunkLength := dbms_lob.getlength(convert(env,'UTF8'));
     --l_chunkLength := 32000;
    dbms_output.put_line ('payload 6 - ');
    env := convert(env,'UTF8');
    dbms_output.put_line ('payload 7 - ');
    UTL_HTTP.set_header(l_http_request, 'Transfer-Encoding', 'chunked');
    dbms_output.put_line ('payload 8 - ');
    utl_http.set_header(l_http_request, 'SOAPAction','http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService//ErpObjectAttachmentService/uploadAttachmentResponse');
    LOOP
      l_chunkData := NULL;
      l_chunkData := SUBSTR(env, l_chunkStart, l_chunkLength);
      UTL_HTTP.write_text(l_http_request, l_chunkData);
      IF (LENGTH(l_chunkData) < l_chunkLength) 
        THEN EXIT; 
      END IF;
      l_chunkStart := l_chunkStart + l_chunkLength;
    END LOOP;
     --  Get the response and process it
     l_http_response := UTL_HTTP.get_response(l_http_request);
    -- Create a CLOB to hold web service response
    dbms_lob.createtemporary(x_clob, FALSE );
    dbms_lob.open(x_clob, dbms_lob.lob_readwrite);
    begin
      loop
        -- Copy the web service response body in a buffer string variable l_buffer
        utl_http.read_text(l_http_response, l_buffer);
      -- Append data from l_buffer to CLOB variable
        dbms_lob.writeappend(x_clob
                          , length(l_buffer)
                          , l_buffer);
      end loop;  
      exception
        when UTL_HTTP.end_of_body then
          dbms_output.put_line ('Error Last 1- ' ||sqlerrm);
          UTL_HTTP.end_response(l_http_response);
    end;
  l_start_position := instr(x_clob,'env:Envelope',1,1)-1;
  l_position := instr(x_clob,'env:Envelope',l_start_position,2);
  x_clob := substr(x_clob , l_start_position , l_position - l_start_position+13);
    if l_http_response.status_code = 200 THEN
      l_resp_xml := XMLType.createXML(x_clob);
    SELECT  extractValue(l_resp_xml, 
    '//result','xmlns="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types/"')
    INTO l_result_value
    FROM dual;
    dbms_output.put_line('Result is = '||l_result_value);
      commit;
    end if;
    dbms_lob.freetemporary(x_clob);
    
    exception
      when others then      
       UTL_HTTP.end_response(l_http_response);
        dbms_output.put_line ('Error Last- ' ||sqlerrm);
    end;
    return l_result_value;
  END xx_erp_attach_doc_p;
  
  procedure XX_MOVE_TEMP_FILES(P_SOURCE_FILE_DIR varchar2, P_SOURCE_FILE_NAME varchar2, P_TARGET_FILE_DIR varchar2, P_TARGET_FILE_NAME varchar2)
  as
  begin
    BEGIN
         UTL_FILE.FRENAME ( 
                             P_SOURCE_FILE_DIR,
                             P_SOURCE_FILE_NAME,
                             P_TARGET_FILE_DIR,
                             P_TARGET_FILE_NAME,
                             TRUE
                          );
    END;
  end;
  
  procedure XX_EXECUTE_ATTACH(P_DIR varchar2, P_INPUT_FILENAME varchar2, P_INPUT_FILE_NAME varchar2, P_BAR_CODE varchar2, P_INPUT_FN_ENCRIPT varchar2, p_password varchar2)
  as
    v_out clob;
    
    v_attach_response varchar2(100);
    
    l_user_key1 varchar2(240);
    l_user_key2 varchar2(240);
    l_user_key3 varchar2(240);
    l_user_key4 varchar2(240);
    l_user_key5 varchar2(240);
    
    l_is_invoiced varchar2(10);
    
  begin
  
        XX_GET_AP_INV_DETAILS(P_BAR_CODE, l_user_key1, l_user_key2, l_user_key3, l_user_key4, l_user_key5, l_is_invoiced);
  
        IF l_is_invoiced = 'INVOICED'
        THEN
        
            XX_BASE64_ENCODE_FILE(P_DIR => 'AITKEN_IMG', P_INPUT_FILENAME => P_INPUT_FILENAME, P_ENCODED_FILENAME => 'APINV_ENCODE_TMP.txt');

            begin
                v_out := XX_BASE64_DECODE_FILE_F(P_DIR => 'AITKEN_IMG', P_INPUT_FILENAME => 'APINV_ENCODE_TMP.txt');
            end;
        
            v_attach_response := XX_ERP_ATTACH_DOC_P(p_password => p_password, p_file => P_INPUT_FILENAME, p_user_key1 => l_user_key1, p_user_key2 => l_user_key2, p_user_key3 => l_user_key3, p_user_key4 => l_user_key4, p_user_key5 => l_user_key5);
        
            IF v_attach_response not like '%SUCCEEDED%'
            THEN
                XX_MOVE_TEMP_FILES('AITKEN_IMG', P_INPUT_FILENAME, 'AITKEN_IMG_BAD',P_INPUT_FILENAME||'_'||systimestamp);
                v_attach_response := NULL;
            ELSE
                XX_MOVE_TEMP_FILES('AITKEN_IMG', P_INPUT_FILENAME, 'AITKEN_IMG_DONE',P_INPUT_FILENAME||'_'||systimestamp);
                v_attach_response := NULL;
            END IF;
        
        END IF;
  end;
  
  procedure XX_EXECUTE
  as
    cursor cur
    is
        select REPLACE(UPPER(FILENAME),UPPER('.tif')) FILE_NAME, FILENAME
        from (select FILE_NAME filename from LIST_ERP_FILES_XT)
        where UPPER(substr(regexp_substr(filename, '\.[^\.]*$'), 2)) = UPPER('tif');
  
  begin
      for c1 in cur
        loop
            XX_EXECUTE_ATTACH(P_DIR => 'AITKEN_IMG', P_INPUT_FILENAME => c1.FILENAME, P_INPUT_FILE_NAME => c1.FILE_NAME, P_BAR_CODE => c1.FILE_NAME, P_INPUT_FN_ENCRIPT => 'APINV_ENCODE_TMP.txt', p_password => 'Lakshani@12345');
        end loop;
  end;
  
  procedure create_schedule--use sys user
  as
  begin
    dbms_scheduler.create_job(job_name        => 'XX_ERP_ATTACH_JOB',
                              job_type        => 'STORED_PROCEDURE',
                              job_action      => 'AITKEN.XX_ERP_INV_ATTACH_PKG.XX_EXECUTE',
                              start_date      => systimestamp,
                              end_date        => null,
                              repeat_interval => 'freq=hourly; byminute=30;',
                              enabled         => true,
                              auto_drop       => false,
                              comments        => 'ERP invoice attachment schedule...');
  end;
  
  procedure XX_DROP_JOB_SCHEDULE--use sys user
  as
  begin
    dbms_scheduler.drop_job ('XX_ERP_ATTACH_JOB');
  end;

END XX_ERP_INV_ATTACH_PKG;

/
