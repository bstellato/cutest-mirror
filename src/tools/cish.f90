! THIS VERSION: CUTEST 1.0 - 29/12/2012 AT 14:05 GMT.

!-*-*-*-*-*-*-*-  C U T E S T    C I S H    S U B R O U T I N E  -*-*-*-*-*-*-

!  Copyright reserved, Gould/Orban/Toint, for GALAHAD productions
!  Principal author: Nick Gould

!  History -
!   fortran 2003 version released in CUTEst, 29th December 2012

      SUBROUTINE CUTEST_cish( status, n, X, iprob, nnzh, lh,                   &
                              H_val, H_row, H_col )
      USE CUTEST
      INTEGER, PARAMETER :: wp = KIND( 1.0D+0 )

!  dummy arguments

      INTEGER, INTENT( IN ) :: n, iprob, lh
      INTEGER, INTENT( OUT ) :: nnzh, status
      INTEGER, INTENT( OUT ), DIMENSION( lh ) :: H_row, H_col
      REAL ( KIND = wp ), INTENT( IN ), DIMENSION( n ) :: X
      REAL ( KIND = wp ), INTENT( OUT ), DIMENSION( lh ) :: H_val

!  ---------------------------------------------------------------
!  compute the Hessian matrix of a specified problem function 
!  (iprob = 0 is the objective function, while iprob > 0 is the 
!  iprob-th constraint) of a problem initially written in 
!  Standard Input Format (SIF).

!  The upper triangle of the Hessian is stored in coordinate form,
!  i.e., the entry H_val(i) has row index H_row(i) and column index 
!  H_col(i) for i = 1, ...., nnzh
!  ---------------------------------------------------------------

      CALL CUTEST_cish_threadsafe( CUTEST_data_global,                         &
                                   CUTEST_work_global( 1 ),                    &
                                   status, n, X, iprob,                        &
                                   nnzh, lh, H_val, H_row, H_col )
      RETURN

!  end of subroutine CUTEST_cish

      END SUBROUTINE CUTEST_cish

!-*-*-*-  C U T E S T   C I S H _ t h r e a d e d   S U B R O U T I N E  -*-*-*-

!  Copyright reserved, Gould/Orban/Toint, for GALAHAD productions
!  Principal author: Nick Gould

!  History -
!   fortran 2003 version released in CUTEst, 29th December 2012

      SUBROUTINE CUTEST_cish_threaded( status, n, X, iprob, nnzh, lh,          &
                                       H_val, H_row, H_col, thread )
      USE CUTEST
      INTEGER, PARAMETER :: wp = KIND( 1.0D+0 )

!  dummy arguments

      INTEGER, INTENT( IN ) :: n, iprob, lh, thread
      INTEGER, INTENT( OUT ) :: nnzh, status
      INTEGER, INTENT( OUT ), DIMENSION( lh ) :: H_row, H_col
      REAL ( KIND = wp ), INTENT( IN ), DIMENSION( n ) :: X
      REAL ( KIND = wp ), INTENT( OUT ), DIMENSION( lh ) :: H_val

!  ---------------------------------------------------------------
!  compute the Hessian matrix of a specified problem function 
!  (iprob = 0 is the objective function, while iprob > 0 is the 
!  iprob-th constraint) of a problem initially written in 
!  Standard Input Format (SIF).

!  The upper triangle of the Hessian is stored in coordinate form,
!  i.e., the entry H_val(i) has row index H_row(i) and column index 
!  H_col(i) for i = 1, ...., nnzh
!  ---------------------------------------------------------------

!  check that the specified thread is within range

      IF ( thread < 1 .OR. thread > CUTEST_data_global%threads ) THEN
        IF ( CUTEST_data_global%out > 0 )                                      &
          WRITE( CUTEST_data_global%out, "( ' ** CUTEST error: thread ', I0,   &
         &  ' out of range [1,', I0, ']' )" ) thread, CUTEST_data_global%threads
        status = 4 ; RETURN
      END IF

!  evaluate using specified thread

      CALL CUTEST_cish_threadsafe( CUTEST_data_global,                         &
                                   CUTEST_work_global( thread ),               &
                                   status, n, X, iprob,                        &
                                   nnzh, lh, H_val, H_row, H_col )
      RETURN

!  end of subroutine CUTEST_cish_threaded

      END SUBROUTINE CUTEST_cish_threaded

!-*-*-  C U T E S T   C I S H _ t h r e a d s a f e   S U B R O U T I N E  -*-*-

!  Copyright reserved, Gould/Orban/Toint, for GALAHAD productions
!  Principal author: Nick Gould

!  History -
!   fortran 77 version originally released in CUTE, August 1998
!   fortran 2003 version released in CUTEst, 24th November 2012

      SUBROUTINE CUTEST_cish_threadsafe( data, work, status, n, X, iprob,      &
                                         nnzh, lh, H_val, H_row, H_col )
      USE CUTEST
      INTEGER, PARAMETER :: wp = KIND( 1.0D+0 )

!  dummy arguments

      TYPE ( CUTEST_data_type ), INTENT( IN ) :: data
      TYPE ( CUTEST_work_type ), INTENT( INOUT ) :: work
      INTEGER, INTENT( IN ) :: n, iprob, lh
      INTEGER, INTENT( OUT ) :: nnzh, status
      INTEGER, INTENT( OUT ), DIMENSION( lh ) :: H_row, H_col
      REAL ( KIND = wp ), INTENT( IN ), DIMENSION( n ) :: X
      REAL ( KIND = wp ), INTENT( OUT ), DIMENSION( lh ) :: H_val

!  ---------------------------------------------------------------
!  compute the Hessian matrix of a specified problem function 
!  (iprob = 0 is the objective function, while iprob > 0 is the 
!  iprob-th constraint) of a problem initially written in 
!  Standard Input Format (SIF).

!  The upper triangle of the Hessian is stored in coordinate form,
!  i.e., the entry H_val(i) has row index H_row(i) and column index 
!  H_col(i) for i = 1, ...., nnzh
!  ---------------------------------------------------------------

!  local variables

      INTEGER :: i, ig, j, ncalcf, ncalcg, ifstat, igstat, alloc_status
      REAL ( KIND = wp ) :: ftt
      CHARACTER ( LEN = 80 ) :: bad_alloc = REPEAT( ' ', 80 )
      EXTERNAL :: RANGE 

!  check input parameters

      IF ( iprob < 0 ) THEN
         IF ( data%out > 0 ) WRITE( data%out, "( ' ** SUBROUTINE CISH: ',      &
        &    'invalid problem index iprob = ', I0 )" ) iprob
         status = 2 ; RETURN
      END IF

!  find group index ig of constraint iprob

      IF ( iprob > 0 ) THEN
         ig = 0
         DO i = 1, data%ng
            IF ( data%KNDOFC( i ) == iprob ) THEN
              ig = i
              EXIT
            END IF
         END DO
         IF ( ig == 0 ) THEN
           IF ( data%out > 0 ) WRITE( data%out, "( ' ** SUBROUTINE CISH: ',    &
          &    'invalid problem index iprob = ', I0 )" ) iprob
            status = 2 ; RETURN
         END IF
      END IF

!  find which elements are involved in the required problem function.
!  Initialize the list to zero

      DO i = 1, data%nel
        work%ICALCF( i ) = 0
      END DO

!  if group ig is involved, record its elements

      DO ig = 1, data%ng
        IF ( data%KNDOFC( ig ) == iprob ) THEN
          DO j = data%ISTADG( ig ), data%ISTADG( ig + 1 ) - 1
            work%ICALCF( data%IELING( j ) ) = 1
          END DO
        END IF
      END DO

!  only compute the elements which are involved in the required function

      ncalcf = 0
      DO i = 1, data%nel
        IF ( work%ICALCF( i ) == 1 ) THEN
          ncalcf = ncalcf + 1
          work%ICALCF( ncalcf ) = i

!  if this is the first ever evaluation, initialize FUVALS

        ELSE
          IF ( work%firstg ) THEN
            work%FUVALS( i ) = 0.0_wp
            DO j = data%INTVAR( i ), data%INTVAR( i + 1 ) - 1
              work%FUVALS( j ) = 0.0_wp
            END DO
            DO j = data%ISTADH( i ), data%ISTADH( i + 1 ) - 1
              work%FUVALS( j ) = 0.0_wp
            END DO
          END IF
        END IF
      END DO

!  evaluate the element function values

      CALL ELFUN( work%FUVALS, X, data%EPVALU, ncalcf, data%ITYPEE,            &
                  data%ISTAEV, data%IELVAR, data%INTVAR, data%ISTADH,          &
                  data%ISTEP, work%ICALCF, data%ltypee, data%lstaev,           &
                  data%lelvar, data%lntvar, data%lstadh, data%lstep,           &
                  data%lcalcf, data%lfuval, data%lvscal, data%lepvlu,          &
                  1, ifstat )
      IF ( ifstat /= 0 ) GO TO 930

!  evaluate the element function derivatives

      CALL ELFUN( work%FUVALS, X, data%EPVALU, ncalcf, data%ITYPEE,            &
                  data%ISTAEV, data%IELVAR, data%INTVAR, data%ISTADH,          &
                  data%ISTEP, work%ICALCF, data%ltypee, data%lstaev,           &
                  data%lelvar, data%lntvar, data%lstadh, data%lstep,           &
                  data%lcalcf, data%lfuval, data%lvscal, data%lepvlu,          &
                  3, ifstat )
      IF ( ifstat /= 0 ) GO TO 930

!  Compute the list of groups involved in the required problem function

      ncalcg = 0
      DO ig = 1, data%ng
         IF ( data%KNDOFC( ig ) == iprob ) THEN
            ncalcg = ncalcg + 1
            work%ICALCF( ncalcg ) = ig

!  compute the group argument values ft

            ftt = - data%B( ig )

!  include the contribution from the linear element

            DO j = data%ISTADA( ig ), data%ISTADA( ig + 1 ) - 1
               ftt = ftt + data%A( j ) * X( data%ICNA( j ) )
            END DO

!  include the contributions from the nonlinear elements

            DO j = data%ISTADG( ig ), data%ISTADG( ig + 1 ) - 1
               ftt = ftt + data%ESCALE( j ) *  &
                      work%FUVALS( data%IELING( j ) )
            END DO
            work%FT( ig ) = ftt

!  record the derivatives of trivial groups

            IF ( data%GXEQX( ig ) ) THEN
               work%GVALS( ig, 2 ) = 1.0_wp
               work%GVALS( ig, 3 ) = 0.0_wp
            END IF
         ELSE

!  if this is the first ever evaluation, initialize GVALS

            IF ( work%firstg ) THEN
               work%GVALS( ig, 2 ) = 1.0_wp
               work%GVALS( ig, 3 ) = 0.0_wp
            END IF
         END IF
      END DO

!  evaluate the group derivative values

      IF ( .NOT. data%altriv ) THEN
        CALL GROUP( work%GVALS, data%ng, work%FT, data%GPVALU, ncalcg,         &
                    data%ITYPEG, data%ISTGP, work%ICALCF, data%ltypeg,         &
                    data%lstgp, data%lcalcf, data%lcalcg, data%lgpvlu,         &
                    .TRUE., igstat )
        IF ( igstat /= 0 ) GO TO 930
      END IF

!  change the group weightings to isolate the required function

      IF ( data%numcon > 0 ) THEN
         DO ig = 1, data%ng
            i = data%KNDOFC( ig )
            IF ( i == iprob ) THEN
               work%GSCALE_used( ig ) = data%GSCALE( ig )
            ELSE
               work%GSCALE_used( ig ) = 0.0_wp
            END IF
         END DO

!  compute the gradient value

        CALL CUTEST_form_gradients( n, data%ng, data%nel, data%ntotel,         &
               data%nvrels, data%nnza, data%nvargp, work%firstg, data%ICNA,    &
               data%ISTADA, data%IELING, data%ISTADG, data%ISTAEV,             &
               data%IELVAR, data%INTVAR, data%A, work%GVALS( : , 2 ),          &
               work%FUVALS, data%lnguvl, work%FUVALS( data%lggfx + 1 ),        &
               work%GSCALE_used, data%ESCALE, work%FUVALS( data%lgrjac + 1 ),  &
               data%GXEQX, data%INTREP, data%ISVGRP, data%ISTAGV, data%ITYPEE, &
               work%ISTAJC, work%W_ws, work%W_el, RANGE )
      ELSE
        CALL CUTEST_form_gradients( n, data%ng, data%nel, data%ntotel,         &
               data%nvrels, data%nnza, data%nvargp, work%firstg, data%ICNA,    &
               data%ISTADA, data%IELING, data%ISTADG, data%ISTAEV,             &
               data%IELVAR, data%INTVAR, data%A, work%GVALS( : , 2 ),          &
               work%FUVALS, data%lnguvl, work%FUVALS( data%lggfx + 1 ),        &
               data%GSCALE, data%ESCALE, work%FUVALS( data%lgrjac + 1 ),       &
               data%GXEQX, data%INTREP, data%ISVGRP, data%ISTAGV, data%ITYPEE, &
               work%ISTAJC, work%W_ws, work%W_el, RANGE )
      END IF
      work%firstg = .FALSE.

!  assemble the Hessian

      IF ( data%numcon > 0 ) THEN
        CALL CUTEST_assemble_hessian(                                          &
               n, data%ng, data%nel, data%ntotel, data%nvrels, data%nnza,      &
               data%maxsel, data%nvargp, data%ISTADH,                          &
               data%ICNA, data%ISTADA, data%INTVAR, data%IELVAR, data%IELING,  &
               data%ISTADG, data%ISTAEV, data%ISTAGV, data%ISVGRP, data%A,     &
               work%FUVALS, data%lnguvl, work%FUVALS, data%lnhuvl,             &
               work%GVALS( : , 2 ), work%GVALS( :  , 3 ), work%GSCALE_used,    &
               data%ESCALE, data%GXEQX, data%ITYPEE, data%INTREP, RANGE,       &
               0, data%out, data%out, .TRUE., .FALSE.,                         &
               n, status, alloc_status, bad_alloc,                             &
               work%array_status, work%lh_row, work%lh_col, work%lh_val,       &
               work%H_row, work%H_col, work%H_val, work%ROW_start,             &
               work%POS_in_H, work%USED, work%FILLED,                          &
               work%lrowst, work%lpos, work%lused, work%lfilled,               &
               work%W_ws, work%W_el, work%W_in, work%H_el, work%H_in,          &
               nnzh = nnzh )
      ELSE
        CALL CUTEST_assemble_hessian(                                          &
               n, data%ng, data%nel, data%ntotel, data%nvrels, data%nnza,      &
               data%maxsel, data%nvargp, data%ISTADH,                          &
               data%ICNA, data%ISTADA, data%INTVAR, data%IELVAR, data%IELING,  &
               data%ISTADG, data%ISTAEV, data%ISTAGV, data%ISVGRP, data%A,     &
               work%FUVALS, data%lnguvl, work%FUVALS, data%lnhuvl,             &
               work%GVALS( : , 2 ), work%GVALS( :  , 3 ), data%GSCALE,         &
               data%ESCALE, data%GXEQX, data%ITYPEE, data%INTREP, RANGE,       &
               0, data%out, data%out, .TRUE., .FALSE.,                         &
               n, status, alloc_status, bad_alloc,                             &
               work%array_status, work%lh_row, work%lh_col, work%lh_val,       &
               work%H_row, work%H_col, work%H_val, work%ROW_start,             &
               work%POS_in_H, work%USED, work%FILLED,                          &
               work%lrowst, work%lpos, work%lused, work%lfilled,               &
               work%W_ws, work%W_el, work%W_in, work%H_el, work%H_in,          &
               nnzh = nnzh )
      END IF

!  check for errors in the assembly

      IF ( status > 0 ) RETURN

!  record the sparse Hessian

      H_row( : nnzh ) = work%H_row( : nnzh )
      H_col( : nnzh ) = work%H_col( : nnzh )
      H_val( : nnzh ) = work%H_val( : nnzh )

!  update the counters for the report tool

      IF( iprob == 0 ) THEN
        work%nc2oh = work%nc2oh + 1
      ELSE 
        work%nc2ch = work%nc2ch + 1
      END IF 
      status = 0
      RETURN

!  unsuccessful returns

  930 CONTINUE
      IF ( data%out > 0 ) WRITE( data%out,                                     &
        "( ' ** SUBROUTINE CISH: error flag raised during SIF evaluation' )" )
      status = 3
      RETURN

!  end of subroutine CUTEST_cish_threadsafe

      END SUBROUTINE CUTEST_cish_threadsafe
