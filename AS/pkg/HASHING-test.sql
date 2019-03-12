CREATE TABLE XX_ALGPARAMETERS
(
  NAME   VARCHAR2(100 BYTE),
  VALUE  NVARCHAR2(100)
);

INSERT INTO XX_ALGPARAMETERS
   SELECT 'key' NAME,
          RAWTOHEX ('52AB32;^$!ER94988OPS3W21') VALUE
     FROM DUAL
   UNION
   SELECT 'iv' NAME, RAWTOHEX ('TY54ABCX') VALUE FROM DUAL;
COMMIT;

CREATE OR REPLACE FUNCTION AITKEN_TEST.F_DECRYPT (p_input VARCHAR2)
   RETURN VARCHAR2
AS
   v_decrypted_raw     RAW (2000);
   v_key               RAW (320);
   v_encryption_type   PLS_INTEGER := SYS.DBMS_CRYPTO.DES_CBC_PKCS5;
   v_iv                RAW (320);
BEGIN
   SELECT VALUE
     INTO v_key
     FROM AITKEN_TEST.XX_ALGPARAMETERS
    WHERE name = 'key';
   SELECT VALUE
     INTO v_iv
     FROM AITKEN_TEST.XX_ALGPARAMETERS
    WHERE name = 'iv';
   v_decrypted_raw :=
      DBMS_CRYPTO.DECRYPT (
         src   => UTL_ENCODE.base64_decode (UTL_RAW.CAST_TO_RAW (p_input)),
         typ   => v_encryption_type,
         key   => v_key,
         iv    => v_iv);
   RETURN UTL_I18N.RAW_TO_CHAR (v_decrypted_raw, 'AL32UTF8');
END;
/
CREATE OR REPLACE FUNCTION AITKEN_TEST.F_ENCRYPT (p_input VARCHAR2)
   RETURN VARCHAR2
AS
   v_encrypted_raw     RAW (2000);
   v_key               RAW (320);
   v_encryption_type   PLS_INTEGER
      :=   SYS.DBMS_CRYPTO.DES_CBC_PKCS5;
   v_iv                RAW (320);
BEGIN
   SELECT VALUE
     INTO v_key
     FROM AITKEN_TEST.XX_ALGPARAMETERS
    WHERE name = 'key';
   SELECT VALUE
     INTO v_iv
     FROM AITKEN_TEST.XX_ALGPARAMETERS
    WHERE name = 'iv';
   v_encrypted_raw :=
      SYS.DBMS_CRYPTO.encrypt (src   => UTL_I18N.STRING_TO_RAW (p_input, 'AL32UTF8'),
                           typ   => v_encryption_type,
                           key   => v_key,
                           iv    => v_iv);
   RETURN UTL_RAW.CAST_TO_VARCHAR2 (UTL_ENCODE.base64_encode (v_encrypted_raw));
END;
/

grant execute on sys.dbms_crypto to aitken_test;

SELECT 'TEST123TEST' INPUT, 
        AITKEN_TEST.F_ENCRYPT('TEST123TEST') ENCRYPTED_RESULT,
        AITKEN_TEST.F_DECRYPT(AITKEN_TEST.F_ENCRYPT('TEST123TEST')) DECRYPT_RESULT 
FROM DUAL;