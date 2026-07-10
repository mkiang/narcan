# ICD-10 flag pipeline colSums are stable

    Code
      flag_sums(r$flagged)
    Output
                  drug_death           opioid_death          opium_present 
                          42                     26                      2 
              heroin_present  other_natural_present      methadone_present 
                          11                     16                      6 
         other_synth_present       other_op_present unspecified_op_present 
                           7                      9                      0 
                 num_opioids          multi_opioids      unintended_intent 
                          51                     17                     23 
              suicide_intent        homicide_intent    undetermined_intent 
                           6                      6                      7 

# ICD-10 maternal + suicide type colSums are stable

    Code
      c(maternal_death = as.integer(sum(mat$maternal_death, na.rm = TRUE)))
    Output
      maternal_death 
                  12 
    Code
      vapply(c("suicide_firearm", "suicide_poison", "suicide_fall",
        "suicide_suffocation", "suicide_other"), function(cc) as.integer(sum(sui[[cc]],
      na.rm = TRUE)), integer(1))
    Output
          suicide_firearm      suicide_poison        suicide_fall suicide_suffocation 
                        6                   8                   6                   3 
            suicide_other 
                        6 

