package body Jackal_Assurance_Policy
  with SPARK_Mode
is

   function Classify_Doctor (Input : Doctor_Input) return Doctor_Verdict is
   begin
      --  JOP-DOCTOR-001
      case Input.Discovery is
         when Discovery_Not_Installed =>
            return Doctor_Not_Installed;
         when Discovery_Refused =>
            return Doctor_Refused;
         when Discovery_Ready =>
            if Input.Has_Probe_Rows
              and then Input.All_Canonical_Declared
              and then Input.All_Probes_Pass
              and then Input.Identity_Match
            then
               return Doctor_Functional;
            else
               return Doctor_Degraded;
            end if;
      end case;
   end Classify_Doctor;

   function Classify (Input : State_Input) return Display_State is
   begin
      --  JOP-STATE-001, JOP-STATE-002
      if not Input.Report_Present then
         return Indeterminate;
      elsif Input.Has_Error then
         return Refused;
      elsif not Input.Installed then
         return Absent;
      elsif not Input.Identity_Match then
         return Refused;
      elsif Input.Verification = Verification_Fail then
         return Refused;
      elsif Input.Is_Stale then
         return Stale;
      elsif not Input.Has_Probes then
         return Indeterminate;
      elsif not Input.All_Probes_Pass then
         return Degraded;
      elsif Input.Doctor = Doctor_Functional then
         return Verified;
      else
         return Degraded;
      end if;
   end Classify;

   function Assurance_Ceiling
     (Items : Math_Status_Set) return Optional_Math_Status
   is
   begin
      --  JOP-ASSURANCE-001.  Strongest-first branches avoid an invariant whose
      --  proof would obscure the finite policy table.
      if Items (Exact) then
         return (Present => True, Value => Exact);
      elsif Items (Formal_Bounded) then
         return (Present => True, Value => Formal_Bounded);
      elsif Items (Bounded) then
         return (Present => True, Value => Bounded);
      elsif Items (Checked) then
         return (Present => True, Value => Checked);
      elsif Items (Estimated) then
         return (Present => True, Value => Estimated);
      elsif Items (Model_Based) then
         return (Present => True, Value => Model_Based);
      else
         return No_Math_Status;
      end if;
   end Assurance_Ceiling;

   function Strongest_Consequence
     (Items : Consequence_Set) return Optional_Consequence
   is
   begin
      if Items (Safety_Critical) then
         return (Present => True, Value => Safety_Critical);
      elsif Items (Decision_Boundary) then
         return (Present => True, Value => Decision_Boundary);
      elsif Items (Advisory) then
         return (Present => True, Value => Advisory);
      elsif Items (Informational) then
         return (Present => True, Value => Informational);
      else
         return No_Consequence;
      end if;
   end Strongest_Consequence;

   function Consequence_Caps_Assurance
     (Assurance    : Math_Status_Set;
      Consequences : Consequence_Set;
      Carries_Axis : Boolean) return Boolean
   is
   begin
      --  JOP-CAP-001
      if Carries_Axis
        or else Math_Set_Is_Empty (Assurance)
        or else Consequence_Set_Is_Empty (Consequences)
      then
         return False;
      end if;

      return
        Required_Strength (Strongest_Consequence (Consequences).Value)
        < Strength_Of (Assurance_Ceiling (Assurance).Value);
   end Consequence_Caps_Assurance;

end Jackal_Assurance_Policy;
