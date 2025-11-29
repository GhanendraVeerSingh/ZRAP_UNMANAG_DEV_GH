CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    TYPES : t_t_travel_failed    TYPE TABLE FOR FAILED EARLY zi_um_travel_gh_m\\travel,
            t_t_travel_reported  TYPE TABLE FOR REPORTED EARLY zi_um_travel_gh_m\\travel,
            t_t_booking_failed   TYPE TABLE FOR FAILED zi_um_booking_gh_m,
            t_t_booking_reported TYPE TABLE FOR REPORTED zi_um_booking_gh_m.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

*    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
*      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Travel.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Travel.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Travel.

    METHODS read FOR READ
      IMPORTING keys FOR READ Travel RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Travel.

    METHODS rba_Booking FOR READ
      IMPORTING keys_rba FOR READ Travel\_Booking FULL result_requested RESULT result LINK association_links.

    METHODS cba_Booking FOR MODIFY
      IMPORTING entities_cba FOR CREATE Travel\_Booking.

    METHODS map_messages
      IMPORTING
        cid          TYPE abp_behv_cid   OPTIONAL
        travelid     TYPE /dmo/travel_id OPTIONAL
        messages     TYPE /dmo/t_message
      EXPORTING
        failed_added TYPE abap_boolean
      CHANGING
        failed       TYPE t_t_travel_failed
        reported     TYPE t_t_travel_reported.

*  Method definition to populate messages by association
    METHODS map_messages_by_assoc
      IMPORTING
        cid          TYPE abp_behv_cid   OPTIONAL
        is_depended  TYPE abap_boolean   DEFAULT abap_false
        messages     TYPE /dmo/t_message
      EXPORTING
        failed_added TYPE abap_boolean
      CHANGING
        failed       TYPE t_t_booking_failed
        reported     TYPE t_t_booking_reported.



ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.
* EML Statement to get Travel entity data
    READ ENTITIES OF zi_um_travel_gh_m IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TravelId Status ) WITH
    CORRESPONDING #( keys )
    RESULT DATA(wtl_result_travel).

    result = VALUE #( FOR wel_result_travel IN wtl_result_travel
                      ( %tky = wel_result_travel-%tky
                        %assoc-_booking = COND #( WHEN wel_result_travel-Status EQ 'A'
                                                  OR   wel_result_travel-Status EQ 'X'
                                                  THEN if_abap_behv=>fc-o-disabled
                                                  ELSE if_abap_behv=>fc-o-enabled )  ) ).

  ENDMETHOD.

*  METHOD get_instance_authorizations.
*  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD create.
    DATA : wel_travel_in   TYPE /dmo/travel,
           wtl_travel      TYPE /dmo/travel,
           wtl_message     TYPE /dmo/t_message,
           wl_failed_added TYPE abap_boolean.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_entity>).
* Populating structures to create the entity
* Here we will use the mapping defined in Behavior definition instead of populating the fields one by one
* Using CONTROL - This statement will ensure that only those data will be transfered for which control field is not initial
*                 i.e. only fields which got changed
      wel_travel_in = CORRESPONDING #( <fs_entity> MAPPING FROM ENTITY USING CONTROL ).
* Invoking FM to create Travel Entity
      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_CREATE'
        EXPORTING
          is_travel         = CORRESPONDING /dmo/s_travel_in( wel_travel_in )
*         it_booking        =
*         it_booking_supplement =
          iv_numbering_mode = /dmo/if_flight_legacy=>numbering_mode-late
        IMPORTING
          es_travel         = wtl_travel
*         et_booking        =
*         et_booking_supplement =
          et_messages       = wtl_message.

*    Invoking Method to map the messages
      map_messages( EXPORTING
                       cid = <fs_entity>-%cid
                       messages = wtl_message
                     IMPORTING
                       failed_added = wl_failed_added
                     CHANGING
                       failed = failed-travel
                       reported = reported-travel ).

      IF wl_failed_added EQ abap_false.
        INSERT VALUE #( %cid = <fs_entity>-%cid
                        travelid = <fs_entity>-TravelId ) INTO TABLE mapped-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    DATA: wel_travel_in     TYPE /dmo/travel,
          wel_travelx       TYPE /dmo/s_travel_inx,
          wel_travel_update TYPE /dmo/travel,
          wtl_messages      TYPE /dmo/t_message,
          wl_failed_added   TYPE abap_boolean.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_entity>).
*  To get the data mapped to target structure of FM
      wel_travel_in = CORRESPONDING #( <fs_entity> MAPPING FROM ENTITY ).

      wel_travelx-travel_id = <fs_entity>-TravelId.
      wel_travelx-_intx = CORRESPONDING #( <fs_entity>-%control MAPPING FROM ENTITY ).

*  TO invoke the FM
      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_UPDATE'
        EXPORTING
          is_travel   = CORRESPONDING /dmo/s_travel_in( wel_travel_in )
          is_travelx  = wel_travelx
*         it_booking  =
*         it_bookingx =
*         it_booking_supplement  =
*         it_booking_supplementx =
        IMPORTING
          es_travel   = wel_travel_update
*         et_booking  =
*         et_booking_supplement  =
          et_messages = wtl_messages.

* To map the messages
      map_messages(
        EXPORTING
          cid          = <fs_entity>-%cid_ref
          travelid     = <fs_entity>-TravelId
          messages     = wtl_messages
        IMPORTING
          failed_added = wl_failed_added
        CHANGING
          failed       = failed-travel
          reported     = reported-travel
      ).

    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    DATA: wtl_messages    TYPE /dmo/t_message,
          wl_failed_added TYPE abap_boolean.
* Logic for Delete Operation
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_key>).
* Invoking FM for delete the entity instance
      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_DELETE'
        EXPORTING
          iv_travel_id = <fs_key>-TravelId
        IMPORTING
          et_messages  = wtl_messages.

* Mapping the messages
      map_messages(
        EXPORTING
*          cid          =
          travelid     = <fs_key>-TravelId
          messages     = wtl_messages
        IMPORTING
          failed_added = wl_failed_added
        CHANGING
          failed       = failed-travel
         reported     =  reported-travel
      ).
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    DATA: wel_travel      TYPE /dmo/travel,
          wtl_message     TYPE /dmo/t_message,
          wl_failed_added TYPE abap_boolean.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_key>) GROUP BY <fs_key>-%tky.
      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_READ'
        EXPORTING
          iv_travel_id = <fs_key>-TravelId
*         iv_include_buffer     = abap_true
        IMPORTING
          es_travel    = wel_travel
*         et_booking   =
*         et_booking_supplement =
          et_messages  = wtl_message.

*   To map the messages
      map_messages(
        EXPORTING
*        cid          =
          travelid     = <fs_key>-TravelId
          messages     = wtl_message
        IMPORTING
          failed_added = wl_failed_added
        CHANGING
          failed       = failed-travel
          reported     = reported-travel
      ).

* To populate the result
      IF wl_failed_added IS INITIAL.
        INSERT CORRESPONDING #( wel_travel MAPPING TO ENTITY ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock.
*  Invoking API to get the lock object
    TRY.
        DATA(wol_lock) = cl_abap_lock_object_factory=>get_instance( iv_name = '/DMO/ETRAVEL' ).
      CATCH cx_abap_lock_failure INTO DATA(wl_lock_fail).
        RAISE SHORTDUMP wl_lock_fail.
    ENDTRY.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_key>).
      TRY.
          wol_lock->enqueue(
*       it_table_mode =
            it_parameter  = VALUE #( ( name = 'TRAVEL_ID' value = REF #( <fs_key>-TravelId ) ) )
*       _scope        =
*       _wait         =
          ).
        CATCH cx_abap_foreign_lock INTO DATA(wol_lockby_user).
*  To map the messages
          map_messages(
            EXPORTING
*            cid          =
              travelid     = <fs_key>-TravelId
              messages     = VALUE #( ( msgid = '/DMO/CM_FLIGHT_LEGAC'
                                        msgno = '032'
                                        msgty = 'E'
                                        msgv1 = <fs_key>-TravelId
                                        msgv2 = wol_lockby_user->user_name ) )
*          IMPORTING
*            failed_added =
            CHANGING
              failed       = failed-travel
              reported     = reported-travel
          ).
        CATCH cx_abap_lock_failure INTO wl_lock_fail.
          "handle exception
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD rba_Booking.
    DATA: wel_travel_out  TYPE /dmo/travel,
          wtl_booking_out TYPE /dmo/t_booking,
          wtl_messages    TYPE /dmo/t_message,
          wel_booking     LIKE LINE OF result.
* This method will not be called from Transactional/FIORI app during interaction phase or SAVE sequence
* This may be explicitly called by EML statement READ BY ASSOC from some external system or program

    LOOP AT keys_rba ASSIGNING FIELD-SYMBOL(<fs_key_rba>).
* To read travel entity along with its associated entity
      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_READ'
        EXPORTING
          iv_travel_id = <fs_key_rba>-TravelId
        IMPORTING
          es_travel    = wel_travel_out
          et_booking   = wtl_booking_out
          et_messages  = wtl_messages.

* To map the messages
      map_messages(
        EXPORTING
*         cid          =
          travelid     = <fs_key_rba>-TravelId
          messages     = wtl_messages
        IMPORTING
          failed_added = DATA(wl_failed_added)
        CHANGING
          failed       = failed-travel
          reported     = reported-travel
      ).

* If read is successful
      IF wl_failed_added NE abap_true.
        LOOP AT wtl_booking_out ASSIGNING FIELD-SYMBOL(<fs_booking_out>).
* To populate Association link and result
          INSERT VALUE #( source-%tky = <fs_key_rba>-%tky
                          target-%tky = VALUE #( TravelId = <fs_booking_out>-travel_id
                                                 BookingId = <fs_booking_out>-booking_id ) )
          INTO TABLE association_links.

          IF result_requested EQ abap_true.
            wel_booking = CORRESPONDING #( <fs_booking_out> MAPPING TO ENTITY ).
            INSERT wel_booking INTO TABLE result.
          ENDIF.
        ENDLOOP.

      ENDIF.


    ENDLOOP.

  ENDMETHOD.

  METHOD cba_Booking.
    DATA: wtl_old_bookings TYPE /dmo/t_booking,
          wtl_messages     TYPE /dmo/t_message,
          wel_booking      TYPE /dmo/booking.
* Logic for creating booking entity instance
    LOOP AT entities_cba ASSIGNING FIELD-SYMBOL(<fs_entity_cba>).
      DATA(wl_travel_id) = <fs_entity_cba>-TravelId.
* To read all the existing Bookings for travel Id
      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_READ'
        EXPORTING
          iv_travel_id = wl_travel_id
        IMPORTING
          et_booking   = wtl_old_bookings
          et_messages  = wtl_messages.

* To populate the error messages if any
      map_messages(
        EXPORTING
*        cid          =
          travelid     = wl_travel_id
          messages     = wtl_messages
      IMPORTING
        failed_added = DATA(wl_failed_added)
        CHANGING
          failed       = failed-travel
          reported     = reported-travel
      ).

      IF wl_failed_added EQ abap_true.
*  To Populate error messages
        LOOP AT <fs_entity_cba>-%target ASSIGNING FIELD-SYMBOL(<fs_booking>).
          map_messages_by_assoc(
            EXPORTING
              cid          = <fs_booking>-%cid
              is_depended  = abap_true
              messages     = wtl_messages
*          IMPORTING
*            failed_added =
            CHANGING
              failed       = failed-booking
              reported     = reported-booking
          ).
        ENDLOOP.

      ELSE.
        DATA(wl_last_booking_id) = VALUE #( wtl_old_bookings[ lines( wtl_old_bookings ) ]-booking_id OPTIONAL ).

        LOOP AT <fs_entity_cba>-%target ASSIGNING FIELD-SYMBOL(<fs_booking_create>).
          CLEAR : wtl_messages.

          wel_booking = CORRESPONDING #( <fs_booking_create> MAPPING FROM ENTITY USING CONTROL ).
          wl_last_booking_id += 1.
          wel_booking-booking_id = wl_last_booking_id.

          CALL FUNCTION '/DMO/FLIGHT_TRAVEL_UPDATE'
            EXPORTING
              is_travel   = VALUE /dmo/s_travel_in( travel_id = wl_travel_id )
              is_travelx  = VALUE /dmo/s_travel_inx( travel_id = wl_travel_id )
              it_booking  = VALUE /dmo/t_booking_in( ( CORRESPONDING #( wel_booking ) ) )
              it_bookingx = VALUE /dmo/t_booking_inx( ( booking_id = wel_booking-booking_id
                                                        action_code = /dmo/if_flight_legacy=>action_code-create ) )
            IMPORTING
              et_messages = wtl_messages.

* To populate the Messages if any
          map_messages_by_assoc(
            EXPORTING
              cid          = <fs_booking_create>-%cid
              is_depended  = abap_true
              messages     = wtl_messages
            IMPORTING
              failed_added = wl_failed_added
            CHANGING
              failed       = failed-booking
              reported     = reported-booking
          ).

* If no error, need to update the result into mapped table
          IF wl_failed_added NE abap_true.
            INSERT VALUE #( %cid = <fs_booking_create>-%cid
                            travelid = wl_travel_id
                            bookingid = <fs_booking_create>-BookingId ) INTO TABLE mapped-booking.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD map_messages.
* TO initialize the flag
    failed_added = abap_false.

    LOOP AT messages ASSIGNING FIELD-SYMBOL(<fs_message>).
      IF <fs_message>-msgty = 'E' OR <fs_message>-msgty = 'A'.
        APPEND VALUE #( %cid = cid
                        travelid = travelid
                        %fail-cause = zcl_auxl_travel_gh=>get_cause_from_message(
                                        piv_msgid    = <fs_message>-msgid
                                        piv_msgno    = <fs_message>-msgno
*                                        is_dependent = abap_false
                                      ) ) TO failed.
*  To populate the flag
        failed_added = abap_true.
      ENDIF.

* To populate the reported structure
      APPEND VALUE #( %cid = cid
                      travelid = travelid
* NEW_MESSAGE :- Its a standard class which creates Message class Object from the parameter
*                information
                      %msg = new_message(
                               id       = <fs_message>-msgid
                               number   = <fs_message>-msgno
                               severity = if_abap_behv_message=>severity-error
                               v1       = <fs_message>-msgv1
                               v2       = <fs_message>-msgv2
                               v3       = <fs_message>-msgv3
                               v4       = <fs_message>-msgv4
                             ) ) TO reported.

    ENDLOOP.
  ENDMETHOD.

  METHOD map_messages_by_assoc.
* To ensure that cid is not blank
    ASSERT cid IS NOT INITIAL.
* TO initialize the flag
    failed_added = abap_false.

    LOOP AT messages ASSIGNING FIELD-SYMBOL(<fs_message>).
      IF <fs_message>-msgty = 'E' OR <fs_message>-msgty = 'A'.
        APPEND VALUE #( %cid = cid
                        %fail-cause = zcl_auxl_travel_gh=>get_cause_from_message(
                                        piv_msgid    = <fs_message>-msgid
                                        piv_msgno    = <fs_message>-msgno
                                        is_dependent = is_depended
                                      ) ) TO failed.
*  To populate the flag
        failed_added = abap_true.
      ENDIF.

* To populate the reported structure
      APPEND VALUE #( %cid = cid
* NEW_MESSAGE :- Its a standard class which creates Message class Object from the parameter
*                information
                      %msg = new_message(
                               id       = <fs_message>-msgid
                               number   = <fs_message>-msgno
                               severity = if_abap_behv_message=>severity-error
                               v1       = <fs_message>-msgv1
                               v2       = <fs_message>-msgv2
                               v3       = <fs_message>-msgv3
                               v4       = <fs_message>-msgv4
                             ) ) TO reported.

    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
