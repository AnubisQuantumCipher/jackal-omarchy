with Ada.Text_IO;
with Jackal_Assurance_Policy;

procedure Jackal_Assurance_Vectors is
   package Policy renames Jackal_Assurance_Policy;

   function Flag (Mask : Natural; Position : Natural) return Boolean is
     ((Mask / (2 ** Position)) mod 2 = 1);

   procedure Emit_State_Vectors is
      Input : Policy.State_Input;
   begin
      --  JOP-BRIDGE-001: exhaustive finite-domain vectors for Model.js.
      for Mask in 0 .. 127 loop
         for Verification in Policy.Verification_Verdict loop
            for Doctor in Policy.Doctor_Verdict loop
               Input :=
                 (Report_Present  => Flag (Mask, 0),
                  Has_Error       => Flag (Mask, 1),
                  Installed       => Flag (Mask, 2),
                  Identity_Match  => Flag (Mask, 3),
                  Verification    => Verification,
                  Is_Stale        => Flag (Mask, 4),
                  Has_Probes      => Flag (Mask, 5),
                  All_Probes_Pass => Flag (Mask, 6),
                  Doctor           => Doctor);
               Ada.Text_IO.Put_Line
                 ("STATE|" & Natural'Image (Mask)
                  & "|" & Policy.Verification_Verdict'Image (Verification)
                  & "|" & Policy.Doctor_Verdict'Image (Doctor)
                  & "|" & Policy.Display_State'Image
                    (Policy.Classify (Input)));
            end loop;
         end loop;
      end loop;
   end Emit_State_Vectors;

   procedure Emit_Doctor_Vectors is
      Input : Policy.Doctor_Input;
   begin
      --  JOP-DOCTOR-001: exhaustive finite-domain operator-policy vectors.
      for Discovery in Policy.Discovery_Outcome loop
         for Mask in 0 .. 15 loop
            Input :=
              (Discovery              => Discovery,
               Has_Probe_Rows         => Flag (Mask, 0),
               All_Canonical_Declared => Flag (Mask, 1),
               All_Probes_Pass        => Flag (Mask, 2),
               Identity_Match         => Flag (Mask, 3));
            Ada.Text_IO.Put_Line
              ("DOCTOR|" & Policy.Discovery_Outcome'Image (Discovery)
               & "|" & Natural'Image (Mask)
               & "|" & Policy.Doctor_Verdict'Image
                 (Policy.Classify_Doctor (Input)));
         end loop;
      end loop;
   end Emit_Doctor_Vectors;

   procedure Fill_Math_Set
     (Mask  : Natural;
      Items : out Policy.Math_Status_Set)
   is
   begin
      for Item in Policy.Math_Status loop
         Items (Item) := Flag (Mask, Policy.Math_Status'Pos (Item));
      end loop;
   end Fill_Math_Set;

   procedure Fill_Consequence_Set
     (Mask  : Natural;
      Items : out Policy.Consequence_Set)
   is
   begin
      for Item in Policy.Consequence loop
         Items (Item) := Flag (Mask, Policy.Consequence'Pos (Item));
      end loop;
   end Fill_Consequence_Set;

   procedure Emit_Assurance_Vectors is
      Items  : Policy.Math_Status_Set;
      Result : Policy.Optional_Math_Status;
   begin
      --  JOP-BRIDGE-001
      for Mask in 0 .. 63 loop
         Fill_Math_Set (Mask, Items);
         Result := Policy.Assurance_Ceiling (Items);
         Ada.Text_IO.Put_Line
           ("ASSURANCE|" & Natural'Image (Mask)
            & "|" & Boolean'Image (Result.Present)
            & "|" & Policy.Math_Status'Image (Result.Value));
      end loop;
   end Emit_Assurance_Vectors;

   procedure Emit_Cap_Vectors is
      Assurance    : Policy.Math_Status_Set;
      Consequences : Policy.Consequence_Set;
   begin
      --  JOP-BRIDGE-001
      for Assurance_Mask in 0 .. 63 loop
         Fill_Math_Set (Assurance_Mask, Assurance);
         for Consequence_Mask in 0 .. 15 loop
            Fill_Consequence_Set (Consequence_Mask, Consequences);
            for Carries_Axis in Boolean loop
               Ada.Text_IO.Put_Line
                 ("CAP|" & Natural'Image (Assurance_Mask)
                  & "|" & Natural'Image (Consequence_Mask)
                  & "|" & Boolean'Image (Carries_Axis)
                  & "|" & Boolean'Image
                    (Policy.Consequence_Caps_Assurance
                       (Assurance, Consequences, Carries_Axis)));
            end loop;
         end loop;
      end loop;
   end Emit_Cap_Vectors;

begin
   Emit_Doctor_Vectors;
   Emit_State_Vectors;
   Emit_Assurance_Vectors;
   Emit_Cap_Vectors;
end Jackal_Assurance_Vectors;
