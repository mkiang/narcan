# .regex_drug_icd9() is stable (E-codes default; +N-codes)

    Code
      cat(.regex_drug_icd9(), "\n")
    Output
      \<E85\d{2}\>|\<E950[012345]\>|\<E9620\>|\<E980[012345]\> 
    Code
      cat(.regex_drug_icd9(n_codes = TRUE), "\n")
    Output
      \<N909[05]\>|\<N9[67]\d{2}\>|\<N995[24]\>|\<E85\d{2}\>|\<E950[012345]\>|\<E9620\>|\<E980[012345]\> 
    Code
      cat(.regex_drug_icd9(n_codes = TRUE, e_codes = FALSE), "\n")
    Output
      \<N909[05]\>|\<N9[67]\d{2}\>|\<N995[24]\> 

# .regex_opioid_icd9() is stable

    Code
      cat(.regex_opioid_icd9(), "\n")
    Output
      \<E850[012]\> 
    Code
      cat(.regex_opioid_icd9(n_codes = TRUE), "\n")
    Output
      \<N9650\>|\<E850[012]\> 

# .regex_drug_icd10() is stable (UCOD and T-code parts)

    Code
      cat(.regex_drug_icd10(ucod_codes = TRUE), "\n")
    Output
      \<X[46][01234]\d{0,1}\>|\<X85\d{0,1}\>|\<Y1[01234]\d{0,1}\> 
    Code
      cat(.regex_drug_icd10(t_codes = TRUE), "\n")
    Output
      \<T3[6789]\d{0,1}\>|\<T[45]\d{1,2}\> 
    Code
      cat(.regex_drug_icd10(ucod_codes = TRUE, t_codes = TRUE), "\n")
    Output
      \<X[46][01234]\d{0,1}\>|\<X85\d{0,1}\>|\<Y1[01234]\d{0,1}\>|\<T3[6789]\d{0,1}\>|\<T[45]\d{1,2}\> 

# .regex_opioid_icd10() is stable (incl. the T40[012346] nuance)

    Code
      cat(.regex_opioid_icd10(ucod_codes = TRUE), "\n")
    Output
      \<X[46][01234]\d{0,1}\>|\<X85\d{0,1}\>|\<Y1[01234]\d{0,1}\> 
    Code
      cat(.regex_opioid_icd10(t_codes = TRUE), "\n")
    Output
      \<T40[012346]\> 
    Code
      cat(.regex_opioid_icd10(ucod_codes = TRUE, t_codes = TRUE), "\n")
    Output
      \<X[46][01234]\d{0,1}\>|\<X85\d{0,1}\>|\<Y1[01234]\d{0,1}\>|\<T40[012346]\> 

# .regex_maternal_icd10() is stable (WHO; +late)

    Code
      cat(.regex_maternal_icd10(), "\n")
    Output
      \<A34\d{0,1}\>|\<O[012345678]{1}[0-9]{1}\d{0,1}\>|\<O9[01234589]{1}\d{0,1}\> 
    Code
      cat(.regex_maternal_icd10(include_late = TRUE), "\n")
    Output
      \<A34\d{0,1}\>|\<O[012345678]{1}[0-9]{1}\d{0,1}\>|\<O9[01234589]{1}\d{0,1}\>|\<O9[67]{1}\d{0,1}\> 

