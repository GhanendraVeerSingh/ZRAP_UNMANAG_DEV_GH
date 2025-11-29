CLASS zcl_auxl_travel_gh DEFINITION
  PUBLIC
  INHERITING FROM cl_abap_behv
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS : get_cause_from_message
      IMPORTING
                piv_msgid             TYPE sy-msgid
                piv_msgno             TYPE sy-msgno
                is_dependent          TYPE abap_boolean DEFAULT abap_false
      RETURNING VALUE(prv_fail_cause) TYPE if_abap_behv=>t_fail_cause.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_AUXL_TRAVEL_GH IMPLEMENTATION.


  METHOD get_cause_from_message.
    prv_fail_cause = if_abap_behv=>cause-unspecific.

    IF piv_msgid = '/DMO/CM_FLIGHT_LEGAC'.
      CASE piv_msgno.
        WHEN '009'  "Travel Key Initial
        OR   '016'  "Travel does not exist
        OR   '017'. "Booking does not exist
          IF is_dependent EQ abap_true.
            prv_fail_cause = if_abap_behv=>cause-dependency.
          ELSE.
            prv_fail_cause = if_abap_behv=>cause-not_found.
          ENDIF.
        WHEN '032'. " Travel is locked by someone
          prv_fail_cause = if_abap_behv=>cause-locked.
        WHEN '046'. "You are not authorized
          prv_fail_cause = if_abap_behv=>cause-unauthorized.
      ENDCASE.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
