! ( Last modified on 23 Dec 2000 at 22:01:38 )
      SUBROUTINE CEH ( data, status, n, m, X, lv, V, ne, IRNHI, lirnhi, le,  &
                       IPRNHI, HI, lhi, IPRHI, byrows )
      USE CUTEST
      TYPE ( CUTEST_data_type ) :: data
      INTEGER, PARAMETER :: wp = KIND( 1.0D+0 )
      INTEGER :: n, m, lv, ne, le, lirnhi, lhi 
      INTEGER, INTENT( OUT ) :: status
      LOGICAL :: byrows
      INTEGER :: IRNHI ( lirnhi )
      INTEGER :: IPRNHI( le ), IPRHI ( le )
      REAL ( KIND = wp ) :: X ( n ), V ( lv ),  &
                         HI ( lhi )

!  Compute the Hessian matrix of the Lagrangian function of
!  a problem initially written in Standard Input Format (SIF).

!  The matrix is represented in "finite element format", i.e., 

!           ne
!      H = sum H_i, 
!          i=1

!  where each element H_i involves a small subset of the rows of H.
!  H is stored as a list of the row indices involved in each element
!  and the upper triangle of H_i (stored by rows or columns). 
!  Specifically,

!  ne (integer) number of elements
!  IRNHI (integer array) a list of the row indices involved which each
!          element. Those for element i directly proceed those for 
!          element i + 1, i = 1, ..., NE-1
!  IPRNHI (integer array) pointers to the position in IRNHI of the first 
!          row index in each element. IPRNHI(NE + 1) points to the first 
!          empty location in IRPNHI
!  HI (real array) a list of the nonzeros in the upper triangle of
!          H_i, stored by rows, or by columns, for each element. Those 
!          for element i directly proceed those for element, i + 1, 
!          i = 1, ..., NE-1
!  IPRHI (integer array) pointers to the position in HI of the first 
!          nonzero in each element. IPRHI(NE + 1) points to the first 
!          empty location in HI
!  BYROWS (logical) must be set .TRUE. if the upper triangle of each H_i 
!          is to be stored by rows, and .FALSE. if it is to be stored
!          by columns.

!  Based on the minimization subroutine data%laNCELOT/SBMIN
!  by Conn, Gould and Toint.

!  Nick Gould, for CGT productions,
!  November 1994.

!  Local variables

      INTEGER :: i, j, ifstat, igstat, ig, liwkh, inform
      REAL ( KIND = wp ) :: ftt
      EXTERNAL :: RANGE

!  there are non-trivial group functions

      DO i = 1, MAX( data%nel, data%ng )
        data%ICALCF( i ) = i
      END DO

!  evaluate the element function values

      CALL ELFUN( data%FUVALS, X, data%EPVALU, data%nel, data%ITYPEE,          &
                  data%ISTAEV, data%IELVAR, data%INTVAR, data%ISTADH,          &
                  data%ISTEP, data%ICALCF, data%ltypee, data%lstaev,           &
                  data%lelvar, data%lntvar, data%lstadh, data%lstep,           &
                  data%lcalcf, data%lfuval, data%lvscal, data%lepvlu,          &
                  1, ifstat )

!  evaluate the element function gradients and Hessians

      CALL ELFUN( data%FUVALS, X, data%EPVALU, data%nel, data%ITYPEE,          &
                  data%ISTAEV, data%IELVAR, data%INTVAR, data%ISTADH,          &
                  data%ISTEP, data%ICALCF, data%ltypee, data%lstaev,           &
                  data%lelvar, data%lntvar, data%lstadh, data%lstep,           &
                  data%lcalcf, data%lfuval, data%lvscal, data%lepvlu,          &
                  3, ifstat )

!  compute the group argument values ft

      DO ig = 1, data%ng
        ftt = - data%B( ig )

!  include the contribution from the linear element

        DO j = data%ISTADA( ig ), data%ISTADA( ig + 1 ) - 1
          ftt = ftt + data%A( j ) * X( data%ICNA( j ) )
        END DO

!  include the contributions from the nonlinear elements

        DO j = data%ISTADG( ig ), data%ISTADG( ig + 1 ) - 1
          ftt = ftt + data%ESCALE( j ) * data%FUVALS( data%IELING( j ) )
        END DO
        data%FT( ig ) = ftt

!  record the derivatives of trivial groups

        IF ( data%GXEQX( ig ) ) THEN
          data%GVALS( ig, 2 ) = 1.0_wp
          data%GVALS( ig, 3 ) = 0.0_wp
        END IF
      END DO

!  evaluate the group derivative values.

      IF ( .NOT. data%altriv )                                                 &
        CALL GROUP( data%GVALS, data%ng, data%FT, data%GPVALU, data%ng,        &
                    data%ITYPEG, data%ISTGP, data%ICALCF, data%ltypeg,         &
                    data%lstgp, data%lcalcf, data%lcalcg, data%lgpvlu,         &
                    .TRUE., igstat )

!  define the real work space needed for ELGRD. Ensure that there is 
!  sufficient space

      IF ( data%lwk2 < data%ng ) THEN
         IF ( data%out > 0 ) WRITE( data%out, 2000 )
         status = 2 ; RETURN
      END IF
      IF ( data%numcon > 0 ) THEN

!  change the group weightings to include the contributions from the
!  Lagrange multipliers

        DO ig = 1, data%ng
          i = data%KNDOFC( ig )
          IF ( i == 0 ) THEN
            data%WRK( ig ) = data%GSCALE( ig )
          ELSE
            data%WRK( ig ) = data%GSCALE( ig ) * V( i )
          END IF
        END DO

!  compute the gradient value

        CALL ELGRD( n, data%ng, data%firstg, data%ICNA( 1 ), data%licna, &
                        data%ISTADA( 1 ), data%lstada, data%IELING( 1 ), &
                        data%leling, data%ISTADG( 1 ), data%lstadg, &
                        data%ITYPEE( 1 ), data%lintre, &
                        data%ISTAEV( 1 ), data%lstaev, data%IELVAR( 1 ), &
                        data%lelvar, data%INTVAR( 1 ), data%lntvar, &
                        data%IWORK( data%lsvgrp + 1 ), &
                        data%lnvgrp, data%IWORK( data%lstajc + 1 ), &
                        data%lnstjc, &
                        data%IWORK( data%lstagv + 1 ), data%lnstgv, &
                        data%A( 1 ), data%la, &
                        data%GVALS( : , 2 ), data%lgvals, &
                        data%FUVALS, data%lnguvl, &
                        data%FUVALS( data%lggfx + 1 ), &
                        data%WRK( 1 ), data%ng, &
                        data%ESCALE( 1 ), data%lescal, &
                        data%FUVALS( data%lgrjac + 1 ), &
                        data%lngrjc, data%WRK( 1 ), data%WRK( n + 1 ), &
                        data%maxsel, &
                        data%GXEQX( 1 ), data%lgxeqx, &
                        data%INTREP( 1 ), data%lintre, RANGE )
      ELSE

!  compute the gradient value

        CALL ELGRD( n, data%ng, data%firstg, data%ICNA( 1 ), data%licna, &
                        data%ISTADA( 1 ), data%lstada, data%IELING( 1 ), &
                        data%leling, data%ISTADG( 1 ), data%lstadg, &
                        data%ITYPEE( 1 ), data%lintre, &
                        data%ISTAEV( 1 ), data%lstaev, data%IELVAR( 1 ), &
                        data%lelvar, data%INTVAR( 1 ), data%lntvar, &
                        data%IWORK( data%lsvgrp + 1 ), &
                        data%lnvgrp, data%IWORK( data%lstajc + 1 ), &
                        data%lnstjc, &
                        data%IWORK( data%lstagv + 1 ), data%lnstgv, &
                        data%A( 1 ), data%la, &
                        data%GVALS( : , 2 ), data%lgvals, &
                        data%FUVALS, data%lnguvl, &
                        data%FUVALS( data%lggfx + 1 ), &
                        data%GSCALE( 1 ), data%lgscal, &
                        data%ESCALE( 1 ), data%lescal, &
                        data%FUVALS( data%lgrjac + 1 ), &
                        data%lngrjc, data%WRK( 1 ), data%WRK( n + 1 ), &
                        data%maxsel, &
                        data%GXEQX( 1 ), data%lgxeqx, &
                        data%INTREP( 1 ), data%lintre, RANGE )
      END IF
      data%firstg = .FALSE.

!  define the real work space needed for ASMBE. Ensure that there is 
!  sufficient space

      IF ( data%numcon > 0 ) THEN
        IF ( data%lwk2 < n + 3 * data%maxsel + data%ng ) THEN
          IF ( data%out > 0 ) WRITE( data%out, 2000 )
          status = 2 ; RETURN
        END IF
      ELSE
        IF ( data%lwk2 < n + 3 * data%maxsel ) THEN
          IF ( data%out > 0 ) WRITE( data%out, 2000 )
          status = 2 ; RETURN
        END IF
      END IF

!  define the integer work space needed for ASMBE. Ensure that there is 
!  sufficient space

      liwkh = data%liwk2 - n

!  assemble the Hessian

      IF ( data%numcon > 0 ) THEN
        CALL ASMBE( n, data%ng, data%maxsel,  &
                        data%ISTADH( 1 ), data%lstadh, &
                        data%ICNA( 1 ), data%licna, &
                        data%ISTADA( 1 ), data%lstada, &
                        data%INTVAR( 1 ), data%lntvar, &
                        data%IELVAR( 1 ), data%lelvar, &
                        data%IELING( 1 ), data%leling, &
                        data%ISTADG( 1 ), data%lstadg, &
                        data%ISTAEV( 1 ), data%lstaev, &
                        data%IWORK( data%lstagv + 1 ), data%lnstgv, &
                        data%IWORK( data%lsvgrp + 1 ), data%lnvgrp, &
                        data%IWORK( liwkh + 1 ), data%liwk2 - liwkh, &
                        data%A( 1 ), data%la, data%FUVALS, data%lnguvl, &
                        data%FUVALS, data%lnhuvl, &
                        data%GVALS( : , 2 ), data%GVALS( : , 3 ), &
                        data%WRK( 1 ), data%ESCALE( 1 ), data%lescal, &
                        data%WRK( data%ng + 1 ), data%lwk2 - data%ng, &
                        data%GXEQX( 1 ), data%lgxeqx, data%INTREP( 1 ), &
                        data%lintre, data%ITYPEE( 1 ), data%lintre, &
                        RANGE, ne, &
                        IRNHI, lirnhi, IPRNHI, HI, lhi, IPRHI, &
                        BYROWS, 1, data%out, inform )
      ELSE
        CALL ASMBE( n, data%ng, data%maxsel,  &
                        data%ISTADH( 1 ), data%lstadh, &
                        data%ICNA( 1 ), data%licna, &
                        data%ISTADA( 1 ), data%lstada, &
                        data%INTVAR( 1 ), data%lntvar, &
                        data%IELVAR( 1 ), data%lelvar, &
                        data%IELING( 1 ), data%leling, &
                        data%ISTADG( 1 ), data%lstadg, &
                        data%ISTAEV( 1 ), data%lstaev, &
                        data%IWORK( data%lstagv + 1 ), data%lnstgv, &
                        data%IWORK( data%lsvgrp + 1 ), data%lnvgrp, &
                        data%IWORK( liwkh + 1 ), data%liwk2 - liwkh, &
                        data%A( 1 ), data%la, data%FUVALS, data%lnguvl, &
                        data%FUVALS, data%lnhuvl, &
                        data%GVALS( : , 2 ), data%GVALS( : , 3 ), &
                        data%GSCALE( 1 ), data%ESCALE( 1 ), data%lescal, &
                        data%WRK( 1 ), data%lwk2 - data%ng, &
                        data%GXEQX( 1 ), data%lgxeqx, data%INTREP( 1 ), &
                        data%lintre, data%ITYPEE( 1 ), data%lintre, &
                        RANGE, ne, &
                        IRNHI, lirnhi, IPRNHI, HI, lhi, IPRHI, &
                        BYROWS, 1, data%out, inform )
      END IF

!  check that there is room for the elements

      IF ( inform > 0 ) THEN
        IF ( data%out > 0 ) WRITE( data%out, 2020 )
        status = 2 ; RETURN
      END IF

!     write( 6, * ) 'ceh: lirnhi = ', lirnhi
!     write( 6, * ) 'ceh: irnhi = ', (IRNHI(I), I=1,LIRNHI)

!  update the counters for the report tool

      data%nc2oh = data%nc2oh + 1
      data%nc2ch = data%nc2ch + data%pnc
      status = 0
      RETURN

! Non-executable statements.

 2000 FORMAT( ' ** SUBROUTINE CEH: Increase the size of WK ' )
 2020 FORMAT( ' ** SUBROUTINE CEH: Increase the size of', &
              ' IPNRHI, IPRHI, IRNHI or HI ' )

!  end of CEH.

      END



