*&---------------------------------------------------------------------*
*& Class: ZCL_TRANSLATION_UTILITIES
*& Purpose: Utility methods for translation handling
*& Usage: Common functions for translation operations
*&---------------------------------------------------------------------*
CLASS zcl_translation_utilities DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    
    " Types for utility operations
    TYPES: BEGIN OF ty_language_info,
             spras TYPE spras,
             sptxt TYPE sptxt,
             laiso TYPE laiso,
           END OF ty_language_info.
    
    TYPES: tt_language_info TYPE TABLE OF ty_language_info.
    
    TYPES: BEGIN OF ty_translation_stats,
             object_type TYPE string,
             total_objects TYPE i,
             translated_objects TYPE i,
             completion_percentage TYPE p DECIMALS 2,
           END OF ty_translation_stats.
    
    TYPES: tt_translation_stats TYPE TABLE OF ty_translation_stats.
    
    " Constants for common operations
    CONSTANTS: BEGIN OF gc_translation_status,
                 complete TYPE string VALUE 'COMPLETE',
                 partial TYPE string VALUE 'PARTIAL',
                 missing TYPE string VALUE 'MISSING',
               END OF gc_translation_status.
    
    " Utility methods
    METHODS: get_available_languages
      RETURNING 
        VALUE(rt_languages) TYPE tt_language_info,
        
      get_translation_statistics
        IMPORTING 
          iv_object_type TYPE string OPTIONAL
        RETURNING 
          VALUE(rt_stats) TYPE tt_translation_stats,
          
      validate_translation_completeness
        IMPORTING 
          iv_object_id TYPE string
          iv_object_type TYPE string
          it_required_languages TYPE table OPTIONAL
        RETURNING 
          VALUE(rv_status) TYPE string,
          
      convert_language_code
        IMPORTING 
          iv_input_code TYPE string
          iv_input_format TYPE string  " 'SAP', 'ISO', 'LOCALE'
          iv_output_format TYPE string " 'SAP', 'ISO', 'LOCALE'
        RETURNING 
          VALUE(rv_output_code) TYPE string,
          
      generate_translation_template
        IMPORTING 
          iv_object_type TYPE string
          iv_source_language TYPE spras DEFAULT 'EN'
          it_target_languages TYPE table
        RETURNING 
          VALUE(rv_template) TYPE string,
          
      detect_text_language
        IMPORTING 
          iv_text TYPE string
        RETURNING 
          VALUE(rv_language) TYPE spras,
          
      clean_translation_text
        IMPORTING 
          iv_input_text TYPE string
        RETURNING 
          VALUE(rv_clean_text) TYPE string,
          
      compare_translations
        IMPORTING 
          iv_object_id TYPE string
          iv_object_type TYPE string
          iv_language1 TYPE spras
          iv_language2 TYPE spras
        RETURNING 
          VALUE(rv_similarity) TYPE p.

  PRIVATE SECTION.
    
    " Private helper methods
    METHODS: calculate_similarity
      IMPORTING 
        iv_text1 TYPE string
        iv_text2 TYPE string
      RETURNING 
        VALUE(rv_similarity) TYPE p,
        
      normalize_text
        IMPORTING 
          iv_text TYPE string
        RETURNING 
          VALUE(rv_normalized) TYPE string.

ENDCLASS.

CLASS zcl_translation_utilities IMPLEMENTATION.

  METHOD get_available_languages.
    " Get all available languages from T002
    SELECT spras, sptxt, laiso
      FROM t002
      WHERE spras IS NOT NULL
      ORDER BY sptxt
      INTO TABLE rt_languages.
      
  ENDMETHOD.

  METHOD get_translation_statistics.
    " Calculate translation statistics
    " This is a simulated implementation
    
    " In real implementation, query custom translation tables
    " and calculate statistics
    
    " Sample statistics data
    rt_stats = VALUE #(
      ( object_type = 'CUSTOM_FIELD' 
        total_objects = 100 
        translated_objects = 85 
        completion_percentage = '85.00' )
      ( object_type = 'CUSTOM_TABLE' 
        total_objects = 50 
        translated_objects = 40 
        completion_percentage = '80.00' )
      ( object_type = 'CUSTOM_MESSAGE' 
        total_objects = 200 
        translated_objects = 180 
        completion_percentage = '90.00' )
    ).
    
    " Filter by object type if specified
    IF iv_object_type IS NOT INITIAL.
      DELETE rt_stats WHERE object_type <> iv_object_type.
    ENDIF.
    
  ENDMETHOD.

  METHOD validate_translation_completeness.
    " Check if all required translations exist
    DATA: lt_required_languages TYPE TABLE OF spras,
          lv_missing_count TYPE i,
          lv_total_count TYPE i.
    
    " Default required languages if not provided
    IF it_required_languages IS INITIAL.
      lt_required_languages = VALUE #( ( 'EN' ) ( 'DE' ) ( 'FR' ) ( 'ES' ) ).
    ELSE.
      " Convert input table to spras table
      " This would need proper implementation based on input structure
      lt_required_languages = VALUE #( ( 'EN' ) ( 'DE' ) ).
    ENDIF.
    
    lv_total_count = lines( lt_required_languages ).
    
    " Check each required language
    LOOP AT lt_required_languages INTO DATA(lv_language).
      " In real implementation, check if translation exists
      " SELECT SINGLE object_id FROM zcustom_translations
      " WHERE object_id = iv_object_id
      "   AND object_type = iv_object_type
      "   AND language = lv_language.
      
      " Simulate some missing translations
      IF lv_language = 'ES' OR lv_language = 'FR'.
        lv_missing_count = lv_missing_count + 1.
      ENDIF.
    ENDLOOP.
    
    " Determine status
    IF lv_missing_count = 0.
      rv_status = gc_translation_status-complete.
    ELSEIF lv_missing_count = lv_total_count.
      rv_status = gc_translation_status-missing.
    ELSE.
      rv_status = gc_translation_status-partial.
    ENDIF.
    
  ENDMETHOD.

  METHOD convert_language_code.
    " Convert between different language code formats
    DATA: lv_sap_code TYPE spras,
          lv_iso_code TYPE laiso.
    
    CASE iv_input_format.
      WHEN 'SAP'.
        lv_sap_code = iv_input_code.
        
        " Get ISO code from SAP code
        SELECT SINGLE laiso FROM t002
          INTO lv_iso_code
          WHERE spras = lv_sap_code.
          
      WHEN 'ISO'.
        lv_iso_code = iv_input_code.
        
        " Get SAP code from ISO code
        SELECT SINGLE spras FROM t002
          INTO lv_sap_code
          WHERE laiso = lv_iso_code.
          
      WHEN 'LOCALE'.
        " Handle locale format (e.g., 'en_US', 'de_DE')
        " Extract language part
        DATA(lv_lang_part) = substring_before( val = iv_input_code sub = '_' ).
        IF lv_lang_part IS INITIAL.
          lv_lang_part = iv_input_code.
        ENDIF.
        
        " Map common locale codes to SAP codes
        CASE lv_lang_part.
          WHEN 'en'. lv_sap_code = 'E'.
          WHEN 'de'. lv_sap_code = 'D'.
          WHEN 'fr'. lv_sap_code = 'F'.
          WHEN 'es'. lv_sap_code = 'S'.
          WHEN 'it'. lv_sap_code = 'I'.
          WHEN 'pt'. lv_sap_code = 'P'.
          WHEN 'ja'. lv_sap_code = 'J'.
          WHEN 'ko'. lv_sap_code = '3'.
          WHEN 'zh'. lv_sap_code = '1'.
          WHEN OTHERS. lv_sap_code = 'E'.  " Default to English
        ENDCASE.
        
        " Get ISO code
        SELECT SINGLE laiso FROM t002
          INTO lv_iso_code
          WHERE spras = lv_sap_code.
          
    ENDCASE.
    
    " Return in requested format
    CASE iv_output_format.
      WHEN 'SAP'.
        rv_output_code = lv_sap_code.
      WHEN 'ISO'.
        rv_output_code = lv_iso_code.
      WHEN 'LOCALE'.
        " Convert back to locale format
        CASE lv_sap_code.
          WHEN 'E'. rv_output_code = 'en_US'.
          WHEN 'D'. rv_output_code = 'de_DE'.
          WHEN 'F'. rv_output_code = 'fr_FR'.
          WHEN 'S'. rv_output_code = 'es_ES'.
          WHEN 'I'. rv_output_code = 'it_IT'.
          WHEN 'P'. rv_output_code = 'pt_PT'.
          WHEN 'J'. rv_output_code = 'ja_JP'.
          WHEN '3'. rv_output_code = 'ko_KR'.
          WHEN '1'. rv_output_code = 'zh_CN'.
          WHEN OTHERS. rv_output_code = 'en_US'.
        ENDCASE.
    ENDCASE.
    
  ENDMETHOD.

  METHOD generate_translation_template.
    " Generate CSV or XML template for translations
    DATA: lt_target_langs TYPE TABLE OF spras,
          lo_writer TYPE REF TO cl_sxml_string_writer.
    
    " Convert input languages to internal table
    " This would need proper implementation based on input structure
    lt_target_langs = VALUE #( ( 'DE' ) ( 'FR' ) ( 'ES' ) ).
    
    " Create XML template
    lo_writer = cl_sxml_string_writer=>create( type = if_sxml=>co_xt_xml10 ).
    
    TRY.
        lo_writer->open_element( name = 'translation_template' ).
        
        " Add metadata
        lo_writer->open_element( name = 'metadata' ).
        lo_writer->open_element( name = 'object_type' ).
        lo_writer->write_value( iv_object_type ).
        lo_writer->close_element( ).
        lo_writer->open_element( name = 'source_language' ).
        lo_writer->write_value( iv_source_language ).
        lo_writer->close_element( ).
        lo_writer->close_element( ).  " metadata
        
        " Add translation entries
        lo_writer->open_element( name = 'entries' ).
        
        " Sample entries for template
        DO 3 TIMES.
          lo_writer->open_element( name = 'entry' ).
          
          lo_writer->open_element( name = 'object_id' ).
          lo_writer->write_value( |SAMPLE_{ sy-index ALPHA = IN }| ).
          lo_writer->close_element( ).
          
          lo_writer->open_element( name = 'source_text' ).
          lo_writer->write_value( |Sample text { sy-index }| ).
          lo_writer->close_element( ).
          
          " Add target language placeholders
          LOOP AT lt_target_langs INTO DATA(lv_lang).
            lo_writer->open_element( name = |text_{ lv_lang }| ).
            lo_writer->write_value( '' ).  " Empty for translation
            lo_writer->close_element( ).
          ENDLOOP.
          
          lo_writer->close_element( ).  " entry
        ENDDO.
        
        lo_writer->close_element( ).  " entries
        lo_writer->close_element( ).  " translation_template
        
        rv_template = cl_abap_conv_codepage=>create_in( )->convert( lo_writer->get_output( ) ).
        
    CATCH cx_root INTO DATA(lx_error).
      rv_template = |Error generating template: { lx_error->get_text( ) }|.
    ENDTRY.
    
  ENDMETHOD.

  METHOD detect_text_language.
    " Simple language detection based on character patterns
    " This is a basic implementation - in practice, you might use
    " external services or more sophisticated algorithms
    
    DATA: lv_text_upper TYPE string.
    
    lv_text_upper = to_upper( iv_text ).
    
    " Check for common patterns
    " German: umlauts and ß
    IF lv_text_upper CS 'Ä' OR lv_text_upper CS 'Ö' OR 
       lv_text_upper CS 'Ü' OR iv_text CS 'ß'.
      rv_language = 'D'.
      RETURN.
    ENDIF.
    
    " French: accented characters
    IF lv_text_upper CS 'À' OR lv_text_upper CS 'É' OR 
       lv_text_upper CS 'È' OR lv_text_upper CS 'Ç'.
      rv_language = 'F'.
      RETURN.
    ENDIF.
    
    " Spanish: ñ and specific accents
    IF lv_text_upper CS 'Ñ' OR lv_text_upper CS 'Á' OR lv_text_upper CS 'Í'.
      rv_language = 'S'.
      RETURN.
    ENDIF.
    
    " Default to English
    rv_language = 'E'.
    
  ENDMETHOD.

  METHOD clean_translation_text.
    " Clean and normalize translation text
    rv_clean_text = iv_input_text.
    
    " Remove leading/trailing spaces
    rv_clean_text = |{ rv_clean_text ALPHA = OUT }|.
    CONDENSE rv_clean_text.
    
    " Remove multiple consecutive spaces
    REPLACE ALL OCCURRENCES OF '  ' IN rv_clean_text WITH ' '.
    
    " Remove control characters
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN rv_clean_text WITH ' '.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab IN rv_clean_text WITH ' '.
    
    " Trim again after cleanup
    CONDENSE rv_clean_text.
    
  ENDMETHOD.

  METHOD compare_translations.
    " Compare two translations and return similarity percentage
    DATA: lv_text1 TYPE string,
          lv_text2 TYPE string.
    
    " In real implementation, get texts from translation table
    " For simulation, use sample texts
    lv_text1 = |Sample text in language { iv_language1 }|.
    lv_text2 = |Sample text in language { iv_language2 }|.
    
    " Calculate similarity
    rv_similarity = calculate_similarity( 
      iv_text1 = lv_text1
      iv_text2 = lv_text2
    ).
    
  ENDMETHOD.

  METHOD calculate_similarity.
    " Simple similarity calculation based on character comparison
    " In practice, you might use more sophisticated algorithms like
    " Levenshtein distance or fuzzy matching
    
    DATA: lv_matches TYPE i,
          lv_total TYPE i,
          lv_min_length TYPE i.
    
    " Normalize texts
    DATA(lv_norm1) = normalize_text( iv_text1 ).
    DATA(lv_norm2) = normalize_text( iv_text2 ).
    
    " Calculate character-by-character similarity
    lv_min_length = nmin( val1 = strlen( lv_norm1 ) val2 = strlen( lv_norm2 ) ).
    lv_total = nmax( val1 = strlen( lv_norm1 ) val2 = strlen( lv_norm2 ) ).
    
    DO lv_min_length TIMES.
      IF lv_norm1+sy-index(1) = lv_norm2+sy-index(1).
        lv_matches = lv_matches + 1.
      ENDIF.
    ENDDO.
    
    " Calculate percentage
    IF lv_total > 0.
      rv_similarity = ( lv_matches / lv_total ) * 100.
    ELSE.
      rv_similarity = 0.
    ENDIF.
    
  ENDMETHOD.

  METHOD normalize_text.
    " Normalize text for comparison
    rv_normalized = to_upper( iv_text ).
    
    " Remove spaces and punctuation
    REPLACE ALL OCCURRENCES OF ' ' IN rv_normalized WITH ''.
    REPLACE ALL OCCURRENCES OF '.' IN rv_normalized WITH ''.
    REPLACE ALL OCCURRENCES OF ',' IN rv_normalized WITH ''.
    REPLACE ALL OCCURRENCES OF '!' IN rv_normalized WITH ''.
    REPLACE ALL OCCURRENCES OF '?' IN rv_normalized WITH ''.
    
  ENDMETHOD.

ENDCLASS.