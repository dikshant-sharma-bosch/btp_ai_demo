*&---------------------------------------------------------------------*
*& Class: ZCL_TRANSLATION_MANAGER
*& Purpose: Manage creation, update, and deletion of translations
*& Usage: Handle CRUD operations for custom translation tables
*&---------------------------------------------------------------------*
CLASS zcl_translation_manager DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    
    " Types for translation management
    TYPES: BEGIN OF ty_translation_entry,
             object_id    TYPE string,
             object_type  TYPE string,
             language     TYPE spras,
             text_content TYPE string,
             created_by   TYPE syuname,
             created_on   TYPE sydatum,
             changed_by   TYPE syuname,
             changed_on   TYPE sydatum,
           END OF ty_translation_entry.
    
    TYPES: tt_translation_entries TYPE TABLE OF ty_translation_entry.
    
    TYPES: BEGIN OF ty_translation_key,
             object_id   TYPE string,
             object_type TYPE string,
             language    TYPE spras,
           END OF ty_translation_key.
    
    TYPES: BEGIN OF ty_translation_result,
             success TYPE abap_bool,
             message TYPE string,
             entries_processed TYPE i,
           END OF ty_translation_result.
    
    " Constants for object types
    CONSTANTS: BEGIN OF gc_object_types,
                 custom_field TYPE string VALUE 'CUSTOM_FIELD',
                 custom_table TYPE string VALUE 'CUSTOM_TABLE',
                 custom_message TYPE string VALUE 'CUSTOM_MESSAGE',
                 custom_report TYPE string VALUE 'CUSTOM_REPORT',
               END OF gc_object_types.
    
    " Public methods for translation management
    METHODS: create_translation
      IMPORTING 
        is_translation TYPE ty_translation_entry
      RETURNING 
        VALUE(rs_result) TYPE ty_translation_result,
        
      update_translation
        IMPORTING 
          is_translation TYPE ty_translation_entry
        RETURNING 
          VALUE(rs_result) TYPE ty_translation_result,
          
      delete_translation
        IMPORTING 
          is_key TYPE ty_translation_key
        RETURNING 
          VALUE(rs_result) TYPE ty_translation_result,
          
      get_translation
        IMPORTING 
          is_key TYPE ty_translation_key
        RETURNING 
          VALUE(rs_translation) TYPE ty_translation_entry,
          
      get_all_translations
        IMPORTING 
          iv_object_id TYPE string OPTIONAL
          iv_object_type TYPE string OPTIONAL
          iv_language TYPE spras OPTIONAL
        RETURNING 
          VALUE(rt_translations) TYPE tt_translation_entries,
          
      batch_create_translations
        IMPORTING 
          it_translations TYPE tt_translation_entries
        RETURNING 
          VALUE(rs_result) TYPE ty_translation_result,
          
      export_translations
        IMPORTING 
          iv_object_type TYPE string OPTIONAL
          iv_language TYPE spras OPTIONAL
        RETURNING 
          VALUE(rv_xml_data) TYPE string,
          
      import_translations
        IMPORTING 
          iv_xml_data TYPE string
          iv_overwrite TYPE abap_bool DEFAULT abap_false
        RETURNING 
          VALUE(rs_result) TYPE ty_translation_result.

  PRIVATE SECTION.
    
    " Private validation and helper methods
    METHODS: validate_translation_entry
      IMPORTING 
        is_translation TYPE ty_translation_entry
      RETURNING 
        VALUE(rv_valid) TYPE abap_bool,
        
      validate_language
        IMPORTING 
          iv_language TYPE spras
        RETURNING 
          VALUE(rv_valid) TYPE abap_bool,
          
      check_translation_exists
        IMPORTING 
          is_key TYPE ty_translation_key
        RETURNING 
          VALUE(rv_exists) TYPE abap_bool,
          
      get_next_object_id
        IMPORTING 
          iv_object_type TYPE string
        RETURNING 
          VALUE(rv_object_id) TYPE string,
          
      log_translation_change
        IMPORTING 
          is_translation TYPE ty_translation_entry
          iv_operation TYPE string.

ENDCLASS.

CLASS zcl_translation_manager IMPLEMENTATION.

  METHOD create_translation.
    " Initialize result
    CLEAR rs_result.
    
    " Validate input
    IF validate_translation_entry( is_translation ) = abap_false.
      rs_result-success = abap_false.
      rs_result-message = 'Invalid translation entry provided'.
      RETURN.
    ENDIF.
    
    " Check if translation already exists
    DATA(ls_key) = VALUE ty_translation_key(
      object_id = is_translation-object_id
      object_type = is_translation-object_type
      language = is_translation-language
    ).
    
    IF check_translation_exists( ls_key ) = abap_true.
      rs_result-success = abap_false.
      rs_result-message = |Translation already exists for { is_translation-object_id } in { is_translation-language }|.
      RETURN.
    ENDIF.
    
    " Prepare translation entry with system fields
    DATA(ls_translation) = is_translation.
    ls_translation-created_by = sy-uname.
    ls_translation-created_on = sy-datum.
    ls_translation-changed_by = sy-uname.
    ls_translation-changed_on = sy-datum.
    
    " Insert into custom translation table (simulated)
    " In real implementation, this would be:
    " INSERT zcustom_translations FROM ls_translation.
    
    TRY.
        " Simulated database operation
        " INSERT zcustom_translations FROM ls_translation.
        
        " Log the change
        log_translation_change( 
          is_translation = ls_translation
          iv_operation = 'CREATE'
        ).
        
        rs_result-success = abap_true.
        rs_result-message = 'Translation created successfully'.
        rs_result-entries_processed = 1.
        
        " Commit work
        COMMIT WORK.
        
    CATCH cx_root INTO DATA(lx_error).
      ROLLBACK WORK.
      rs_result-success = abap_false.
      rs_result-message = |Error creating translation: { lx_error->get_text( ) }|.
    ENDTRY.
    
  ENDMETHOD.

  METHOD update_translation.
    " Initialize result
    CLEAR rs_result.
    
    " Validate input
    IF validate_translation_entry( is_translation ) = abap_false.
      rs_result-success = abap_false.
      rs_result-message = 'Invalid translation entry provided'.
      RETURN.
    ENDIF.
    
    " Check if translation exists
    DATA(ls_key) = VALUE ty_translation_key(
      object_id = is_translation-object_id
      object_type = is_translation-object_type
      language = is_translation-language
    ).
    
    IF check_translation_exists( ls_key ) = abap_false.
      rs_result-success = abap_false.
      rs_result-message = |Translation does not exist for { is_translation-object_id } in { is_translation-language }|.
      RETURN.
    ENDIF.
    
    " Prepare update with system fields
    DATA(ls_translation) = is_translation.
    ls_translation-changed_by = sy-uname.
    ls_translation-changed_on = sy-datum.
    
    TRY.
        " Update translation in custom table (simulated)
        " UPDATE zcustom_translations SET
        "   text_content = ls_translation-text_content,
        "   changed_by = ls_translation-changed_by,
        "   changed_on = ls_translation-changed_on
        " WHERE object_id = ls_translation-object_id
        "   AND object_type = ls_translation-object_type
        "   AND language = ls_translation-language.
        
        " Log the change
        log_translation_change( 
          is_translation = ls_translation
          iv_operation = 'UPDATE'
        ).
        
        rs_result-success = abap_true.
        rs_result-message = 'Translation updated successfully'.
        rs_result-entries_processed = 1.
        
        COMMIT WORK.
        
    CATCH cx_root INTO DATA(lx_error).
      ROLLBACK WORK.
      rs_result-success = abap_false.
      rs_result-message = |Error updating translation: { lx_error->get_text( ) }|.
    ENDTRY.
    
  ENDMETHOD.

  METHOD delete_translation.
    " Initialize result
    CLEAR rs_result.
    
    " Validate key
    IF is_key-object_id IS INITIAL OR 
       is_key-object_type IS INITIAL OR 
       is_key-language IS INITIAL.
      rs_result-success = abap_false.
      rs_result-message = 'Invalid translation key provided'.
      RETURN.
    ENDIF.
    
    " Check if translation exists
    IF check_translation_exists( is_key ) = abap_false.
      rs_result-success = abap_false.
      rs_result-message = |Translation does not exist for { is_key-object_id } in { is_key-language }|.
      RETURN.
    ENDIF.
    
    TRY.
        " Delete from custom translation table (simulated)
        " DELETE FROM zcustom_translations
        " WHERE object_id = is_key-object_id
        "   AND object_type = is_key-object_type
        "   AND language = is_key-language.
        
        " Log the change
        DATA(ls_translation) = VALUE ty_translation_entry(
          object_id = is_key-object_id
          object_type = is_key-object_type
          language = is_key-language
        ).
        
        log_translation_change( 
          is_translation = ls_translation
          iv_operation = 'DELETE'
        ).
        
        rs_result-success = abap_true.
        rs_result-message = 'Translation deleted successfully'.
        rs_result-entries_processed = 1.
        
        COMMIT WORK.
        
    CATCH cx_root INTO DATA(lx_error).
      ROLLBACK WORK.
      rs_result-success = abap_false.
      rs_result-message = |Error deleting translation: { lx_error->get_text( ) }|.
    ENDTRY.
    
  ENDMETHOD.

  METHOD get_translation.
    " Get single translation entry
    " In real implementation:
    " SELECT SINGLE * FROM zcustom_translations INTO rs_translation
    " WHERE object_id = is_key-object_id
    "   AND object_type = is_key-object_type
    "   AND language = is_key-language.
    
    " Simulated response
    rs_translation = VALUE #(
      object_id = is_key-object_id
      object_type = is_key-object_type
      language = is_key-language
      text_content = |Sample text for { is_key-object_id }|
      created_by = 'SYSTEM'
      created_on = sy-datum
    ).
    
  ENDMETHOD.

  METHOD get_all_translations.
    " Get all translations based on optional filters
    " Build dynamic WHERE clause
    DATA: lv_where TYPE string.
    
    " Build WHERE conditions
    IF iv_object_id IS NOT INITIAL.
      lv_where = |OBJECT_ID = '{ iv_object_id }'|.
    ENDIF.
    
    IF iv_object_type IS NOT INITIAL.
      IF lv_where IS NOT INITIAL.
        lv_where = |{ lv_where } AND |.
      ENDIF.
      lv_where = |{ lv_where }OBJECT_TYPE = '{ iv_object_type }'|.
    ENDIF.
    
    IF iv_language IS NOT INITIAL.
      IF lv_where IS NOT INITIAL.
        lv_where = |{ lv_where } AND |.
      ENDIF.
      lv_where = |{ lv_where }LANGUAGE = '{ iv_language }'|.
    ENDIF.
    
    " In real implementation:
    " SELECT * FROM zcustom_translations INTO TABLE rt_translations
    " WHERE (lv_where).
    
    " Simulated response
    rt_translations = VALUE #(
      ( object_id = 'SAMPLE_01' object_type = gc_object_types-custom_field 
        language = 'EN' text_content = 'Sample Field 1' )
      ( object_id = 'SAMPLE_01' object_type = gc_object_types-custom_field 
        language = 'DE' text_content = 'Beispielfeld 1' )
    ).
    
  ENDMETHOD.

  METHOD batch_create_translations.
    " Initialize result
    rs_result-success = abap_true.
    rs_result-entries_processed = 0.
    DATA: lt_errors TYPE TABLE OF string.
    
    LOOP AT it_translations INTO DATA(ls_translation).
      
      " Create individual translation
      DATA(ls_result) = create_translation( ls_translation ).
      
      IF ls_result-success = abap_true.
        rs_result-entries_processed = rs_result-entries_processed + 1.
      ELSE.
        APPEND ls_result-message TO lt_errors.
        rs_result-success = abap_false.
      ENDIF.
      
    ENDLOOP.
    
    " Build result message
    IF rs_result-success = abap_true.
      rs_result-message = |All { rs_result-entries_processed } translations created successfully|.
    ELSE.
      DATA(lv_error_count) = lines( lt_errors ).
      rs_result-message = |{ rs_result-entries_processed } successful, { lv_error_count } failed|.
      
      " Add error details
      LOOP AT lt_errors INTO DATA(lv_error).
        rs_result-message = |{ rs_result-message }. Error: { lv_error }|.
      ENDLOOP.
    ENDIF.
    
  ENDMETHOD.

  METHOD export_translations.
    " Export translations to XML format
    DATA: lo_writer TYPE REF TO cl_sxml_string_writer,
          lt_translations TYPE tt_translation_entries.
    
    " Get translations based on filters
    lt_translations = get_all_translations( 
      iv_object_type = iv_object_type
      iv_language = iv_language
    ).
    
    " Create XML writer
    lo_writer = cl_sxml_string_writer=>create( type = if_sxml=>co_xt_xml10 ).
    
    TRY.
        " Start XML document
        lo_writer->open_element( name = 'translations' ).
        
        LOOP AT lt_translations INTO DATA(ls_translation).
          lo_writer->open_element( name = 'translation' ).
          
          lo_writer->open_element( name = 'object_id' ).
          lo_writer->write_value( ls_translation-object_id ).
          lo_writer->close_element( ).
          
          lo_writer->open_element( name = 'object_type' ).
          lo_writer->write_value( ls_translation-object_type ).
          lo_writer->close_element( ).
          
          lo_writer->open_element( name = 'language' ).
          lo_writer->write_value( ls_translation-language ).
          lo_writer->close_element( ).
          
          lo_writer->open_element( name = 'text_content' ).
          lo_writer->write_value( ls_translation-text_content ).
          lo_writer->close_element( ).
          
          lo_writer->close_element( ).  " translation
        ENDLOOP.
        
        lo_writer->close_element( ).  " translations
        
        " Get XML string
        rv_xml_data = cl_abap_conv_codepage=>create_in( )->convert( lo_writer->get_output( ) ).
        
    CATCH cx_root INTO DATA(lx_error).
      " Handle XML creation error
      rv_xml_data = |Error creating XML: { lx_error->get_text( ) }|.
    ENDTRY.
    
  ENDMETHOD.

  METHOD import_translations.
    " Import translations from XML format
    " This is a simplified implementation
    rs_result-success = abap_false.
    rs_result-message = 'XML import functionality not yet implemented'.
    rs_result-entries_processed = 0.
    
    " TODO: Implement XML parsing and translation import
    " Use cl_sxml_string_reader for XML parsing
    
  ENDMETHOD.

  METHOD validate_translation_entry.
    " Validate all required fields
    rv_valid = abap_true.
    
    " Check required fields
    IF is_translation-object_id IS INITIAL OR
       is_translation-object_type IS INITIAL OR
       is_translation-language IS INITIAL OR
       is_translation-text_content IS INITIAL.
      rv_valid = abap_false.
      RETURN.
    ENDIF.
    
    " Validate language
    IF validate_language( is_translation-language ) = abap_false.
      rv_valid = abap_false.
      RETURN.
    ENDIF.
    
    " Additional validations can be added here
    
  ENDMETHOD.

  METHOD validate_language.
    " Check if language exists in T002 table
    SELECT SINGLE spras FROM t002 
      INTO @DATA(lv_language)
      WHERE spras = @iv_language.
      
    rv_valid = COND #( WHEN sy-subrc = 0 THEN abap_true ELSE abap_false ).
    
  ENDMETHOD.

  METHOD check_translation_exists.
    " Check if translation already exists
    " In real implementation:
    " SELECT SINGLE object_id FROM zcustom_translations
    " INTO @DATA(lv_object_id)
    " WHERE object_id = @is_key-object_id
    "   AND object_type = @is_key-object_type
    "   AND language = @is_key-language.
    
    " For simulation, assume it doesn't exist
    rv_exists = abap_false.
    
  ENDMETHOD.

  METHOD get_next_object_id.
    " Generate next object ID for given type
    " This is a simplified implementation
    DATA: lv_counter TYPE i VALUE 1.
    
    " In real implementation, get max ID from database and increment
    rv_object_id = |{ iv_object_type }_{ lv_counter ALPHA = IN }|.
    
  ENDMETHOD.

  METHOD log_translation_change.
    " Log translation changes for audit purposes
    " In real implementation, write to change log table
    
    " Simulated logging
    DATA: lv_log_message TYPE string.
    
    lv_log_message = |{ iv_operation }: { is_translation-object_id } ({ is_translation-object_type }) - { is_translation-language }|.
    
    " Write to application log or change documents
    " CALL FUNCTION 'BAL_LOG_MSG_ADD' or similar
    
  ENDMETHOD.

ENDCLASS.