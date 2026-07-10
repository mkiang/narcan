# label_od_intent() adds od_intent with the expected label set

    Code
      sort(table(out$od_intent))
    Output
      
          homicide      suicide undetermined   unintended not_overdose 
                 6            6            7           23           44 

# label_suicide_type() adds suicide_type with the expected label set

    Code
      sort(table(out$suicide_type))
    Output
      
      suicide_suffocation        suicide_fall     suicide_firearm       suicide_other 
                        3                   6                   6                   6 
           suicide_poison         not_suicide 
                        8                  57 

