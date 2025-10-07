*&---------------------------------------------------------------------*
*& Report: Z_TRANSLATION_DEMO
*& Purpose: Demonstration program for SAP ABAP translation functionality
*& Usage: Show how to use translation classes and methods
*&---------------------------------------------------------------------*
REPORT z_translation_demo.

" Data declarations
DATA: go_translation_reader TYPE REF TO zcl_translation_reader,
      go_translation_manager TYPE REF TO zcl_translation_manager,
      go_translation_utilities TYPE REF TO zcl_translation_utilities.

" Selection screen parameters
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
PARAMETERS: p_lang TYPE spras DEFAULT sy-langu OBLIGATORY,
            p_ctry TYPE land1 DEFAULT 'DE',
            p_curr TYPE waers DEFAULT 'EUR'.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-002.
PARAMETERS: p_demo1 AS CHECKBOX DEFAULT 'X',
            p_demo2 AS CHECKBOX DEFAULT 'X',
            p_demo3 AS CHECKBOX DEFAULT 'X',
            p_demo4 AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b2.

" Text elements
SELECTION-SCREEN: COMMENT /1(50) text-h01.

" Text symbols
" text-001: 'Basic Parameters'
" text-002: 'Demo Options'
" text-h01: 'SAP ABAP Translation Demonstration Program'

START-OF-SELECTION.

  " Initialize objects
  go_translation_reader = NEW zcl_translation_reader( ).
  go_translation_manager = NEW zcl_translation_manager( ).
  go_translation_utilities = NEW zcl_translation_utilities( ).

  " Execute selected demonstrations
  IF p_demo1 = 'X'.
    PERFORM demo_read_translations.
  ENDIF.

  IF p_demo2 = 'X'.
    PERFORM demo_manage_translations.
  ENDIF.

  IF p_demo3 = 'X'.
    PERFORM demo_translation_utilities.
  ENDIF.

  IF p_demo4 = 'X'.
    PERFORM demo_error_handling.
  ENDIF.

*&---------------------------------------------------------------------*
*& Form: DEMO_READ_TRANSLATIONS
*& Purpose: Demonstrate reading translations from standard SAP tables
*&---------------------------------------------------------------------*
FORM demo_read_translations.

  WRITE: / 'DEMO 1: Reading Translations from Standard Tables',
         / '=' && cl_abap_char_utilities=>horizontal_tab &&
           '=' && cl_abap_char_utilities=>horizontal_tab.

  " Demo 1.1: Read country texts
  WRITE: / 'Country Texts in Language:', p_lang.
  
  DATA(lt_countries) = go_translation_reader->get_country_texts( 
    iv_language = p_lang
    iv_country = p_ctry
  ).
  
  LOOP AT lt_countries INTO DATA(ls_country).
    WRITE: / '  Country:', ls_country-land1, 
           '  Description:', ls_country-landx.
  ENDLOOP.

  " Demo 1.2: Read currency texts
  SKIP 1.
  WRITE: / 'Currency Texts in Language:', p_lang.
  
  DATA(lt_currencies) = go_translation_reader->get_currency_texts( 
    iv_language = p_lang
    iv_currency = p_curr
  ).
  
  LOOP AT lt_currencies INTO DATA(ls_currency).
    WRITE: / '  Currency:', ls_currency-waers, 
           '  Description:', ls_currency-ltext.
  ENDLOOP.

  " Demo 1.3: Read message texts
  SKIP 1.
  WRITE: / 'Message Text Example:'.
  
  DATA(lv_message) = go_translation_reader->get_message_text( 
    iv_message_class = 'SABAPDOCU'
    iv_message_number = '000'
    iv_language = p_lang
    iv_param1 = 'Parameter1'
    iv_param2 = 'Parameter2'
  ).
  
  WRITE: / '  Message:', lv_message.

  " Demo 1.4: Generic text reading with fallback
  SKIP 1.
  WRITE: / 'Generic Text Reading with Fallback:'.
  
  DATA(lv_generic_text) = go_translation_reader->get_text_with_fallback( 
    iv_table_name = 'T005T'
    iv_text_field = 'LANDX'
    iv_key_field = 'LAND1'
    iv_key_value = p_ctry
    iv_language = p_lang
  ).
  
  WRITE: / '  Generic Country Text:', lv_generic_text.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form: DEMO_MANAGE_TRANSLATIONS
*& Purpose: Demonstrate translation management operations
*&---------------------------------------------------------------------*
FORM demo_manage_translations.

  SKIP 2.
  WRITE: / 'DEMO 2: Translation Management Operations',
         / '=' && cl_abap_char_utilities=>horizontal_tab &&
           '=' && cl_abap_char_utilities=>horizontal_tab.

  " Demo 2.1: Create translation
  DATA(ls_translation) = VALUE zcl_translation_manager=>ty_translation_entry(
    object_id = 'DEMO_OBJECT_001'
    object_type = zcl_translation_manager=>gc_object_types-custom_field
    language = 'EN'
    text_content = 'Demo Custom Field Label'
  ).
  
  DATA(ls_result) = go_translation_manager->create_translation( ls_translation ).
  
  WRITE: / 'Create Translation Result:'.
  WRITE: / '  Success:', ls_result-success,
         / '  Message:', ls_result-message.

  " Demo 2.2: Update translation
  ls_translation-text_content = 'Updated Demo Custom Field Label'.
  
  ls_result = go_translation_manager->update_translation( ls_translation ).
  
  WRITE: / 'Update Translation Result:'.
  WRITE: / '  Success:', ls_result-success,
         / '  Message:', ls_result-message.

  " Demo 2.3: Get all translations
  DATA(lt_all_translations) = go_translation_manager->get_all_translations( 
    iv_object_type = zcl_translation_manager=>gc_object_types-custom_field
  ).
  
  WRITE: / 'All Translations for Custom Fields:'.
  LOOP AT lt_all_translations INTO DATA(ls_trans).
    WRITE: / '  Object:', ls_trans-object_id, 
           '  Language:', ls_trans-language,
           '  Text:', ls_trans-text_content.
  ENDLOOP.

  " Demo 2.4: Batch create translations
  DATA: lt_batch_translations TYPE zcl_translation_manager=>tt_translation_entries.
  
  lt_batch_translations = VALUE #(
    ( object_id = 'BATCH_001' object_type = 'CUSTOM_FIELD' 
      language = 'EN' text_content = 'Batch Field 1' )
    ( object_id = 'BATCH_001' object_type = 'CUSTOM_FIELD' 
      language = 'DE' text_content = 'Stapelfeld 1' )
    ( object_id = 'BATCH_002' object_type = 'CUSTOM_FIELD' 
      language = 'EN' text_content = 'Batch Field 2' )
  ).
  
  ls_result = go_translation_manager->batch_create_translations( lt_batch_translations ).
  
  WRITE: / 'Batch Create Result:'.
  WRITE: / '  Success:', ls_result-success,
         / '  Entries Processed:', ls_result-entries_processed,
         / '  Message:', ls_result-message.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form: DEMO_TRANSLATION_UTILITIES
*& Purpose: Demonstrate utility functions for translations
*&---------------------------------------------------------------------*
FORM demo_translation_utilities.

  SKIP 2.
  WRITE: / 'DEMO 3: Translation Utility Functions',
         / '=' && cl_abap_char_utilities=>horizontal_tab &&
           '=' && cl_abap_char_utilities=>horizontal_tab.

  " Demo 3.1: Get available languages
  DATA(lt_languages) = go_translation_utilities->get_available_languages( ).
  
  WRITE: / 'Available Languages (First 5):'.
  LOOP AT lt_languages INTO DATA(ls_language) TO 5.
    WRITE: / '  Code:', ls_language-spras, 
           '  Description:', ls_language-sptxt,
           '  ISO:', ls_language-laiso.
  ENDLOOP.

  " Demo 3.2: Translation statistics
  DATA(lt_stats) = go_translation_utilities->get_translation_statistics( ).
  
  SKIP 1.
  WRITE: / 'Translation Statistics:'.
  LOOP AT lt_stats INTO DATA(ls_stat).
    WRITE: / '  Type:', ls_stat-object_type,
           '  Total:', ls_stat-total_objects,
           '  Translated:', ls_stat-translated_objects,
           '  Completion:', ls_stat-completion_percentage, '%'.
  ENDLOOP.

  " Demo 3.3: Language code conversion
  SKIP 1.
  WRITE: / 'Language Code Conversion:'.
  
  DATA(lv_sap_code) = go_translation_utilities->convert_language_code( 
    iv_input_code = 'en_US'
    iv_input_format = 'LOCALE'
    iv_output_format = 'SAP'
  ).
  
  WRITE: / '  en_US (LOCALE) -> SAP:', lv_sap_code.
  
  DATA(lv_iso_code) = go_translation_utilities->convert_language_code( 
    iv_input_code = 'D'
    iv_input_format = 'SAP'
    iv_output_format = 'ISO'
  ).
  
  WRITE: / '  D (SAP) -> ISO:', lv_iso_code.

  " Demo 3.4: Text language detection
  SKIP 1.
  WRITE: / 'Text Language Detection:'.
  
  DATA(lv_detected_lang1) = go_translation_utilities->detect_text_language( 
    'This is an English text sample'
  ).
  WRITE: / '  "This is an English text..." -> Detected:', lv_detected_lang1.
  
  DATA(lv_detected_lang2) = go_translation_utilities->detect_text_language( 
    'Das ist ein deutscher Textbeispiel mit Umlauten: äöü'
  ).
  WRITE: / '  "Das ist ein deutscher Text..." -> Detected:', lv_detected_lang2.

  " Demo 3.5: Translation completeness validation
  SKIP 1.
  WRITE: / 'Translation Completeness Check:'.
  
  DATA(lv_status) = go_translation_utilities->validate_translation_completeness( 
    iv_object_id = 'SAMPLE_OBJECT'
    iv_object_type = 'CUSTOM_FIELD'
  ).
  
  WRITE: / '  Status for SAMPLE_OBJECT:', lv_status.

  " Demo 3.6: Text cleaning
  SKIP 1.
  WRITE: / 'Text Cleaning:'.
  
  DATA(lv_dirty_text) = |  Sample   text  with  extra   spaces  { cl_abap_char_utilities=>cr_lf }and newlines  |.
  DATA(lv_clean_text) = go_translation_utilities->clean_translation_text( lv_dirty_text ).
  
  WRITE: / '  Original: "', lv_dirty_text, '"'.
  WRITE: / '  Cleaned:  "', lv_clean_text, '"'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form: DEMO_ERROR_HANDLING
*& Purpose: Demonstrate error handling in translation operations
*&---------------------------------------------------------------------*
FORM demo_error_handling.

  SKIP 2.
  WRITE: / 'DEMO 4: Error Handling Examples',
         / '=' && cl_abap_char_utilities=>horizontal_tab &&
           '=' && cl_abap_char_utilities=>horizontal_tab.

  " Demo 4.1: Invalid language handling
  WRITE: / 'Testing with Invalid Language (ZZ):'.
  
  DATA(lt_invalid_countries) = go_translation_reader->get_country_texts( 
    iv_language = 'ZZ'  " Invalid language
    iv_country = 'US'
  ).
  
  IF lines( lt_invalid_countries ) = 0.
    WRITE: / '  No results for invalid language - fallback should occur'.
  ELSE.
    LOOP AT lt_invalid_countries INTO DATA(ls_country).
      WRITE: / '  Fallback result - Country:', ls_country-land1, 
             '  Description:', ls_country-landx.
    ENDLOOP.
  ENDIF.

  " Demo 4.2: Empty translation creation
  SKIP 1.
  WRITE: / 'Testing Empty Translation Creation:'.
  
  DATA(ls_empty_translation) = VALUE zcl_translation_manager=>ty_translation_entry(
    object_id = ''  " Empty object ID
    object_type = ''
    language = ''
    text_content = ''
  ).
  
  DATA(ls_error_result) = go_translation_manager->create_translation( ls_empty_translation ).
  
  WRITE: / '  Success:', ls_error_result-success,
         / '  Error Message:', ls_error_result-message.

  " Demo 4.3: Non-existent translation update
  SKIP 1.
  WRITE: / 'Testing Update of Non-existent Translation:'.
  
  DATA(ls_nonexistent) = VALUE zcl_translation_manager=>ty_translation_entry(
    object_id = 'NONEXISTENT_OBJECT'
    object_type = 'CUSTOM_FIELD'
    language = 'EN'
    text_content = 'This should fail'
  ).
  
  ls_error_result = go_translation_manager->update_translation( ls_nonexistent ).
  
  WRITE: / '  Success:', ls_error_result-success,
         / '  Error Message:', ls_error_result-message.

  " Demo 4.4: Language validation
  SKIP 1.
  WRITE: / 'Language Validation Examples:'.
  
  " Test valid languages
  DATA: lv_lang_test TYPE spras.
  
  lv_lang_test = 'E'.
  WRITE: / '  Language E valid:', 
         COND string( WHEN lv_lang_test IS NOT INITIAL THEN 'Yes' ELSE 'No' ).
  
  lv_lang_test = 'ZZ'.  " Invalid
  SELECT SINGLE spras FROM t002 INTO lv_lang_test WHERE spras = 'ZZ'.
  WRITE: / '  Language ZZ valid:', 
         COND string( WHEN sy-subrc = 0 THEN 'Yes' ELSE 'No' ).

  SKIP 1.
  WRITE: / 'End of Translation Demonstration Program'.

ENDFORM.