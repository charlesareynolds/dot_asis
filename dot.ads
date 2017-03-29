-- This package provides support for creating and printing graphs in the
-- DOT language, described at www.graphviz.org.  From the website:
--
-- The following is an abstract grammar defining the DOT language.  Literal
-- characters and keywords are given in single quotes. Parentheses ( and )
-- indicate grouping when needed. Square brackets [ and ] enclose optional items.
-- Vertical bars | separate alternatives.
--
-- graph        : ['strict'] ('graph'|'digraph') [ID] '{' stmt_list '}'
-- stmt_list    : [stmt [';'] stmt_list]
-- stmt         : node_stmt
--              | edge_stmt
--              | attr_stmt
-- 	        | ID '=' ID
--              | subgraph
-- attr_stmt    : ('graph'|'node'|'edge') attr_list
-- attr_list    : '[' [ a_list] ']' [attr_list]
-- a_list       : ID '=' ID [(';'|',')] [a_list]
-- edge_stmt    : (node_id | subgraph) edgeRHS [attr_list]
-- edgeRHS      : edgeop (node_id | subgraph) [edgeRHS]
-- node_stmt 	: node_id [attr_list]
-- node_id 	: ID [port]
-- port         : ':' ID [':'compass_pt]
--              | ':' compass_pt
-- subgraph     : ['subgraph' [ID]] '{' stmt_list '}'
-- compass_pt   : ('n'|'ne'|'e'|'se'|'s'|'sw'|'w'|'nw'|'c'|'_')
--
-- The keywords node, edge, graph, digraph, subgraph, and strict are
-- case-independent. Note also that the allowed compass point values are not
-- keywords, so these strings can be used elsewhere as ordinary identifiers and,
-- conversely, the parser will actually accept any identifier.
--
-- An ID is one of the following:
-- - Any string of alphabetic ([a-zA-Z\200-\377]) characters, underscores ('_')
--   or digits ([0-9]), not beginning with a digit
-- - a numeral [-]?(.[0-9]+ | [0-9]+(.[0-9]*)? )
-- - any double-quoted string ("...") possibly containing escaped quotes ("\"")
-- - an HTML string (<...>)
--
-- An ID is just a string; the lack of quote characters in the first two forms
-- is just for simplicity. There is no semantic difference between abc_2 and
-- "abc_2", or between 2.34 and "2.34". To use a keyword as an ID, it must be
-- quoted.

with Ada.Containers.Doubly_Linked_Lists;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

package Dot is

   -- Using the exact spellings from the grammar for the record components
   -- instead of spelling things out:

   type Compass_Pt_Type is (N, NE, E, SE, S, SW, W, NW, C, Underscore);

   type ID_Type is new Ada.Strings.Unbounded.Unbounded_String;
   function To_ID_Type (Item : in String) return ID_Type
                        renames To_Unbounded_String;
   --     function To_ID_Type (Item : in Wide_String) return ID_Type;

   -----------------------------------------------------------------------------
   package Stmt is

      type Class is abstract tagged null record;
      type Access_All_Class is access all Class'Class;

      procedure Put
        (This : in Class) is abstract;

      package Lists is new
        Ada.Containers.Doubly_Linked_Lists (Access_All_Class);
      -- Make primitive operations like "=" visible:
      type List_Of_Access_All_Class is new Lists.List with null record;

      procedure Put
        (These : in List_Of_Access_All_Class);

   end Stmt;
   -----------------------------------------------------------------------------

   -----------------------------------------------------------------------------
--     type Assign_Class is tagged -- Initialized
--        record
--           L : ID_Type; -- Initialized
--           R : ID_Type; -- Initialized
--        end record;
   -----------------------------------------------------------------------------

   -----------------------------------------------------------------------------
   -- Zero or more assigns:
   package Assign is

      type Class is tagged -- Initialized
      record
         L : ID_Type; -- Initialized
         R : ID_Type; -- Initialized
      end record;

      procedure Put
        (This : in Class);

      package Lists is new
        Ada.Containers.Doubly_Linked_Lists (Class);
      -- Make primitive operations like "=" visible:
      type List_Of_Class is new Lists.List with null record; -- Initialized

      procedure Put
        (These : in List_Of_Class);

      -- Convenience: converts L, R to ID_Type and appends a Class to the list.
      -- Allows this:
      --      Assign_List.Append ("Today", "Thursday");
      -- Instead of this:
      --      Assign_List.Append ((L => Dot.To_ID_Type ("Today"),
      --                               R => Dot.To_ID_Type ("Thursday")));

      not overriding
      procedure Append
        (These : in out List_Of_Class;
         L, R  : in     String);

      Empty_List : constant List_Of_Class := List_Of_Class'(Lists.Empty_List
                                                              with null record);

   end Assign;
   -----------------------------------------------------------------------------

   -----------------------------------------------------------------------------
   -- Zero or more bracketed lists of assigns:
   package Attr is

      type Class is tagged -- Initialized
         record
            Assigns : Assign.List_Of_Class; -- Initialized
         end record;

      procedure Put
        (This : in Class);

      package Lists is new
        Ada.Containers.Doubly_Linked_Lists (Class);
      -- Make primitive operations like "=" visible:
      type List_Of_Class is new Lists.List with null record;

      procedure Put
        (These : in List_Of_Class);

      Empty_List : constant List_Of_Class := List_Of_Class'(Lists.Empty_List
                                                              with null record);

   end Attr;
   -----------------------------------------------------------------------------

   -----------------------------------------------------------------------------
   package Attr_Stmt is

      type Kind_Type is (Graph, Node, Edge);

      type Class is new Stmt.Class with record -- Initialized
         Kind  : Kind_Type := Node;
         Attrs : Dot.Attr.List_Of_Class; -- Initialized
      end record;

      overriding
      procedure Put
        (This : in Class);

      -- Creates a Class object on the heap:
      procedure Append_To
        (This      : in Class;
         Stmt_List : in out Stmt.List_Of_Access_All_Class);

   end Attr_Stmt;
   -----------------------------------------------------------------------------

   -----------------------------------------------------------------------------
   package Node_ID is

      type Port_Class is tagged record -- Initialized
         Has_ID         : Boolean := False;
         ID             : ID_Type; -- Initialized
         Has_Compass_Pt : Boolean := False;
         Compass_Pt     : Compass_Pt_Type := C;
      end record;

      procedure Put
        (This : in Port_Class);

      Null_Port_Class : constant Port_Class;

      type Class is tagged record -- Initialized
         ID       : ID_Type; -- Initialized
         Port     : Port_Class; -- Initialized
      end record;

      procedure Put
        (This : in Class);

   private
      Default_Port_Class : Port_Class;
      Null_Port_Class : constant Port_Class := Default_Port_Class;
   end Node_ID;
   -----------------------------------------------------------------------------

   -----------------------------------------------------------------------------
   package Node_Stmt is

      type Class is new Stmt.Class with record -- Initialized
         Node_ID : Dot.Node_ID.Class; -- Initialized
         Attrs   : Dot.Attr.List_Of_Class; -- Initialized
      end record;

      overriding
      procedure Put
        (This : in Class);

      -- Creates a Class object on the heap:
      procedure Append_To
        (This      : in Class;
         Stmt_List : in out Stmt.List_Of_Access_All_Class);

   end Node_Stmt;
   -----------------------------------------------------------------------------

   -----------------------------------------------------------------------------
   type Subgraph_Class is tagged record -- Initialized
      Stmt_List : Stmt.List_Of_Access_All_Class;
      Has_ID    : Boolean := False;
      ID        : ID_Type;
         end record;
   -----------------------------------------------------------------------------

   -----------------------------------------------------------------------------
   package Edge_Stmt is
      type Kind_Type is (Node, Subgraph);

      type Class is new Stmt.Class with record -- Initialized
         Attrs    : Dot.Attr.List_Of_Class; -- Initialized
         Kind     : Kind_Type := Node;
         Node_ID  : Dot.Node_ID.Class; -- Initialized
         Subgraph : Subgraph_Class; -- Initialized
      end record;

      overriding
      procedure Put
        (This : in Class);

      -- Creates a Class object on the heap:
      procedure Append_To
        (This      : in Class;
         Stmt_List : in out Stmt.List_Of_Access_All_Class);

   end Edge_Stmt;
   -----------------------------------------------------------------------------


   -----------------------------------------------------------------------------
   package Graphs is

      type Class is tagged private; -- Initialized
      type Access_Class is access Class;

      procedure Set_Is_Digraph
        (This : access Class;
         To   : in     Boolean);

      procedure Set_Is_Strict
        (This : access Class;
         To   : in     Boolean);

      procedure Set_ID
        (This : access Class;
         To   : in     String);

      procedure Append_Stmt
        (This     : access Class;
         The_Stmt : in     Stmt.Access_All_Class);

      function Stmt_Count
        (This : access Class)
         return Natural;

      procedure Put
        (This : access Class);

   private

      type Class is tagged-- Initialized
         record
            Digraph   : Boolean := True;
            Strict    : Boolean := True;
            ID        : ID_Type; -- Initialized
            Stmt_List : Stmt.List_Of_Access_All_Class; -- Initialized
         end record;

   end Graphs;
   -----------------------------------------------------------------------------

private
   package ASU renames Ada.Strings.Unbounded;
   package ATI renames Ada.Text_IO;

   -----------------------------------------------------------------------------
   -- Output support:

   package Indented is
      procedure Indent;
      procedure Dedent;
      procedure Put (Item : in String);
      procedure New_Line;

      -- Calls New_Line if the current col is greater than the indent col:
      procedure End_Line_If_Needed;

      -- Put nothing if Item is empty, else Put it with a trailing space:
      procedure Put_Spaced (Item : in String);
   end Indented;

   -- END Output support
   -----------------------------------------------------------------------------


   function To_String (Item : in Compass_Pt_Type)
                       return String;

   -- Returns a quoted string (in case ID is a reserved word), or an empty
   -- string if the ID is empty:
   function To_String (Item : in ID_Type)
                       return String;

   procedure Put (This : in ID_Type);


end Dot;