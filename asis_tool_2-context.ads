with Asis;

with A_Nodes;
with Dot;

package Asis_Tool_2.Context is

   type Class is tagged limited private;

   procedure Process
     (This    : in out Class;
      Outputs : in     Output_Accesses_Record);

private

   type Class is tagged limited -- Initialized
      record
         Asis_Context : Asis.Context; -- Initialized
--           Graph        : Dot.Graphs.Access_Class; -- Initialized
      end record;

end Asis_Tool_2.Context;
