*&---------------------------------------------------------------------*
*& Class: ZCL_TRANSLATION_READER
*& Purpose: Read translated texts from various SAP tables
*& Usage: Handle multilingual text retrieval with fallback logic
*&---------------------------------------------------------------------*
CLASS zcl_translation_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    
    " Types for different translation scenarios
    TYPES: BEGIN OF ty_country_text,
             land1 TYPE land1,
             landx TYPE landx,
             spras TYPE spras,
           END OF ty_country_text.
    
    TYPES: tt_country_texts TYPE TABLE OF ty_country_text.
    
    TYPES: BEGIN OF ty_currency_text,
             waers TYPE waers,
             ltext TYPE ltext,
             spras TYPE spras,
           END OF ty_currency_text.
    
    TYPES: tt_currency_texts TYPE TABLE OF ty_currency_text.
    
    TYPES: BEGIN OF ty_message_text,
             arbgb TYPE arbgb,
             msgnr TYPE msgnr,
             text  TYPE natxt,
             spras TYPE spras,
           END OF ty_message_text.
    
    " Public methods for text retrieval
    METHODS: get_country_texts
      IMPORTING 
        iv_language TYPE spras DEFAULT sy-langu
        iv_country  TYPE land1 OPTIONAL
      RETURNING 
        VALUE(rt_texts) TYPE tt_country_texts,
        
      get_currency_texts
        IMPORTING 
          iv_language TYPE spras DEFAULT sy-langu
          iv_currency TYPE waers OPTIONAL
        RETURNING 
          VALUE(rt_texts) TYPE tt_currency_texts,
          
      get_message_text
        IMPORTING 
          iv_message_class TYPE arbgb
          iv_message_number TYPE msgnr
          iv_language TYPE spras DEFAULT sy-langu
          iv_param1 TYPE string OPTIONAL
          iv_param2 TYPE string OPTIONAL
          iv_param3 TYPE string OPTIONAL
          iv_param4 TYPE string OPTIONAL
        RETURNING 
          VALUE(rv_text) TYPE string,
          
      get_text_with_fallback
        IMPORTING 
          iv_table_name TYPE tabname
          iv_text_field TYPE fieldname
          iv_key_field TYPE fieldname
          iv_key_value TYPE string
          iv_language_field TYPE fieldname DEFAULT 'SPRAS'
          iv_language TYPE spras DEFAULT sy-langu
        RETURNING 
          VALUE(rv_text) TYPE string.

  PRIVATE SECTION.
    
    " Constants for language fallback sequence
    CONSTANTS: BEGIN OF gc_fallback_languages,
                 english TYPE spras VALUE 'E',
                 german  TYPE spras VALUE 'D',
               END OF gc_fallback_languages.
    
    " Private helper methods
    METHODS: build_fallback_languages
      IMPORTING 
        iv_preferred_lang TYPE spras
      RETURNING 
        VALUE(rt_languages) TYPE TABLE,
        
      get_single_text
        IMPORTING 
          iv_table TYPE tabname
          iv_text_field TYPE fieldname
          iv_where_clause TYPE string
        RETURNING 
          VALUE(rv_text) TYPE string.

ENDCLASS.

CLASS zcl_translation_reader IMPLEMENTATION.

  METHOD get_country_texts.
    " Get country texts in specified language with fallback
    DATA: lt_fallback_langs TYPE TABLE OF spras.
    
    lt_fallback_langs = build_fallback_languages( iv_language ).
    
    " Build dynamic WHERE clause
    DATA(lv_where) = COND string( 
      WHEN iv_country IS NOT INITIAL 
      THEN |LAND1 = '{ iv_country }'| 
      ELSE |LAND1 IS NOT NULL| 
    ).
    
    " Try each language in fallback sequence
    LOOP AT lt_fallback_langs INTO DATA(lv_lang).
      
      " Dynamic SQL to handle optional country filter
      IF iv_country IS NOT INITIAL.
        SELECT land1, landx, @lv_lang AS spras
          FROM t005t
          WHERE spras = @lv_lang
            AND land1 = @iv_country
          INTO CORRESPONDING FIELDS OF TABLE @rt_texts.
      ELSE.
        SELECT land1, landx, @lv_lang AS spras
          FROM t005t
          WHERE spras = @lv_lang
          INTO CORRESPONDING FIELDS OF TABLE @rt_texts.
      ENDIF.
      
      " Exit if texts found
      IF lines( rt_texts ) > 0.
        EXIT.
      ENDIF.
      
    ENDLOOP.
    
  ENDMETHOD.

  METHOD get_currency_texts.
    " Get currency texts with fallback logic
    DATA: lt_fallback_langs TYPE TABLE OF spras.
    
    lt_fallback_langs = build_fallback_languages( iv_language ).
    
    LOOP AT lt_fallback_langs INTO DATA(lv_lang).
      
      IF iv_currency IS NOT INITIAL.
        SELECT waers, ltext, @lv_lang AS spras
          FROM tcurt
          WHERE spras = @lv_lang
            AND waers = @iv_currency
          INTO CORRESPONDING FIELDS OF TABLE @rt_texts.
      ELSE.
        SELECT waers, ltext, @lv_lang AS spras
          FROM tcurt
          WHERE spras = @lv_lang
          INTO CORRESPONDING FIELDS OF TABLE @rt_texts.
      ENDIF.
      
      IF lines( rt_texts ) > 0.
        EXIT.
      ENDIF.
      
    ENDLOOP.
    
  ENDMETHOD.

  METHOD get_message_text.
    " Get message text and substitute parameters
    DATA: lv_message TYPE natxt.
    
    " Try to get message in requested language
    SELECT SINGLE text INTO lv_message
      FROM t100
      WHERE sprsl = iv_language
        AND arbgb = iv_message_class
        AND msgnr = iv_message_number.
    
    " Fallback to English if not found
    IF sy-subrc <> 0.
      SELECT SINGLE text INTO lv_message
        FROM t100
        WHERE sprsl = gc_fallback_languages-english
          AND arbgb = iv_message_class
          AND msgnr = iv_message_number.
    ENDIF.
    
    " Substitute parameters in message text
    IF lv_message IS NOT INITIAL.
      rv_text = lv_message.
      
      " Replace placeholders with parameters
      IF iv_param1 IS NOT INITIAL.
        REPLACE '&1' IN rv_text WITH iv_param1.
        REPLACE '&' IN rv_text WITH iv_param1.
      ENDIF.
      
      IF iv_param2 IS NOT INITIAL.
        REPLACE '&2' IN rv_text WITH iv_param2.
      ENDIF.
      
      IF iv_param3 IS NOT INITIAL.
        REPLACE '&3' IN rv_text WITH iv_param3.
      ENDIF.
      
      IF iv_param4 IS NOT INITIAL.
        REPLACE '&4' IN rv_text WITH iv_param4.
      ENDIF.
      
    ENDIF.
    
  ENDMETHOD.

  METHOD get_text_with_fallback.
    " Generic method to get text from any table with fallback
    DATA: lt_fallback_langs TYPE TABLE OF spras,
          lv_where_clause TYPE string.
    
    lt_fallback_langs = build_fallback_languages( iv_language ).
    
    " Build WHERE clause for the query
    lv_where_clause = |{ iv_key_field } = '{ iv_key_value }'|.
    
    LOOP AT lt_fallback_langs INTO DATA(lv_lang).
      
      " Add language condition to WHERE clause
      lv_where_clause = |{ lv_where_clause } AND { iv_language_field } = '{ lv_lang }'|.
      
      " Get text using dynamic SQL
      rv_text = get_single_text(
        iv_table = iv_table_name
        iv_text_field = iv_text_field
        iv_where_clause = lv_where_clause
      ).
      
      IF rv_text IS NOT INITIAL.
        EXIT.
      ENDIF.
      
      " Reset WHERE clause for next language
      lv_where_clause = |{ iv_key_field } = '{ iv_key_value }'|.
      
    ENDLOOP.
    
  ENDMETHOD.

  METHOD build_fallback_languages.
    " Build language fallback sequence
    " 1. Preferred language
    " 2. System language (if different)
    " 3. English
    " 4. German (if not already included)
    
    APPEND iv_preferred_lang TO rt_languages.
    
    IF sy-langu <> iv_preferred_lang.
      APPEND sy-langu TO rt_languages.
    ENDIF.
    
    IF gc_fallback_languages-english NOT IN rt_languages.
      APPEND gc_fallback_languages-english TO rt_languages.
    ENDIF.
    
    IF gc_fallback_languages-german NOT IN rt_languages.
      APPEND gc_fallback_languages-german TO rt_languages.
    ENDIF.
    
  ENDMETHOD.

  METHOD get_single_text.
    " Execute dynamic SQL to get single text value
    DATA: lo_data_ref TYPE REF TO data,
          lo_struct_ref TYPE REF TO data.
    
    FIELD-SYMBOLS: <lt_result> TYPE STANDARD TABLE,
                   <ls_result> TYPE any,
                   <lv_text> TYPE any.
    
    " Create dynamic internal table
    TRY.
        CREATE DATA lo_data_ref TYPE STANDARD TABLE OF (iv_table).
        ASSIGN lo_data_ref->* TO <lt_result>.
        
        " Execute dynamic SELECT
        SELECT * FROM (iv_table)
          INTO TABLE <lt_result>
          WHERE (iv_where_clause).
        
        " Get first result
        READ TABLE <lt_result> INDEX 1 INTO <ls_result>.
        IF sy-subrc = 0.
          ASSIGN COMPONENT iv_text_field OF STRUCTURE <ls_result> TO <lv_text>.
          IF sy-subrc = 0.
            rv_text = <lv_text>.
          ENDIF.
        ENDIF.
        
    CATCH cx_root.
      " Handle any errors in dynamic SQL
      CLEAR rv_text.
    ENDTRY.
    
  ENDMETHOD.

ENDCLASS.