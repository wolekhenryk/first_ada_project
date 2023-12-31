-- A skeleton of a program for an assignment in programming languages
-- The students should rename the tasks of producers, consumers, and the buffer
-- Then, they should change them so that they would fit their assignments
-- They should also complete the code with constructions that lack there
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO;
with Ada.Numerics.Discrete_Random;


procedure main is
   Number_Of_Products: constant Integer := 5;
   Number_Of_Assemblies: constant Integer := 3;
   Number_Of_Consumers: constant Integer := 2;

   subtype Product_Type is Integer range 1 .. Number_Of_Products;
   subtype Assembly_Type is Integer range 1 .. Number_Of_Assemblies;
   subtype Consumer_Type is Integer range 1 .. Number_Of_Consumers;

   Product_Name: constant array (Product_Type) of String(1 .. 8) :=
     ("Radiator", "Wheel   ", "Airbags ", "Sunroof ", "Gearbox ");

   Assembly_Name: constant array (Assembly_Type) of String(1 .. 3)
     := ("BMW", "AMG", "KTM");
   package Random_Assembly is new
     Ada.Numerics.Discrete_Random(Assembly_Type);
   type My_Str is new String(1 ..256);

   -- Producer produces determined product
   task type Producer is
      -- Give the Producer an identity, i.e. the product type
      entry Start(Product: in Product_Type; Production_Time: in Integer);
   end Producer;

   -- Consumer gets an arbitrary assembly of several products from the buffer
   task type Consumer is
      -- Give the Consumer an identity
      entry Start(Consumer_Number: in Consumer_Type;
                  Consumption_Time: in Integer);
   end Consumer;

   -- In the Buffer, products are assemblied into an assembly
   task type Buffer is
      -- Accept a product to the storage provided there is a room for it
      entry Take(Product: in Product_Type; Number: in Integer; Taken: out Boolean);
      -- Deliver an assembly provided there are enough products for it
      entry Deliver(Assembly: in Assembly_Type; Number: out Integer; Delivered: out Boolean);
   end Buffer;

   P: array ( 1 .. Number_Of_Products ) of Producer;
   K: array ( 1 .. Number_Of_Consumers ) of Consumer;
   B: Buffer;

   task body Producer is
      subtype Production_Time_Range is Integer range 3 .. 6;
      package Random_Production is new
        Ada.Numerics.Discrete_Random(Production_Time_Range);
      G: Random_Production.Generator;	--  generator liczb losowych
      Product_Type_Number: Integer;
      Product_Number: Integer;
      Production: Integer;
      Taken: Boolean;
   begin
      accept Start(Product: in Product_Type; Production_Time: in Integer) do
         Random_Production.Reset(G);	--  start random number generator
         Product_Number := 1;
         Product_Type_Number := Product;
         Production := Production_Time;
      end Start;
      Put_Line("Started producer of " & Product_Name(Product_Type_Number));
      loop
         delay Duration(Random_Production.Random(G)); --  symuluj produkcje
         Put_Line("Produced product " & Product_Name(Product_Type_Number)
                  & " number "  & Integer'Image(Product_Number));
         -- Accept for storage
         loop
            select
               B.Take(Product_Type_Number, Product_Number, Taken);
               if (Taken = true) then
                  exit;
               end if;
            or delay 1.0;
               Put_line("Wait");
            end select;
         end loop;
         Product_Number := Product_Number + 1;
      end loop;
   end Producer;

   task body Consumer is
      subtype Consumption_Time_Range is Integer range 4 .. 8;
      package Random_Consumption is new
        Ada.Numerics.Discrete_Random(Consumption_Time_Range);
      G: Random_Consumption.Generator;	--  random number generator (time)
      G2: Random_Assembly.Generator;	--  also (assemblies)
      Consumer_Nb: Consumer_Type;
      Assembly_Number: Integer;
      Consumption: Integer;
      Assembly_Type: Integer;
      Delivered: Boolean := false;
      Consumer_Name: constant array (1 .. Number_Of_Consumers)
        of String(1 .. 9)
        := ("Consumer1", "Consumer2");
   begin
      accept Start(Consumer_Number: in Consumer_Type;
                   Consumption_Time: in Integer) do
         Random_Consumption.Reset(G);	--  ustaw generator
         Random_Assembly.Reset(G2);	--  tez
         Consumer_Nb := Consumer_Number;
         Consumption := Consumption_Time;
      end Start;
      Put_Line("Started consumer " & Consumer_Name(Consumer_Nb));
      loop
         delay Duration(Random_Consumption.Random(G)); --  simulate consumption
         Assembly_Type := Random_Assembly.Random(G2);
         -- take an assembly for consumption
         loop
            select
               B.Deliver(Assembly_Type, Assembly_Number, Delivered);
               if (Delivered = true) then
                  exit;
               end if;
            or delay 1.0;
               Put_line("Wait");
            end select;
         end loop;
         Put_Line(Consumer_Name(Consumer_Nb) & ": taken assembly " &
                    Assembly_Name(Assembly_Type) & " number " &
                    Integer'Image(Assembly_Number));
      end loop;
   end Consumer;

   task body Buffer is
      Storage_Capacity: constant Integer := 32;
      type Storage_type is array (Product_Type) of Integer;
      Storage: Storage_type
        := (0, 0, 0, 0, 0);
      Assembly_Content: array(Assembly_Type, Product_Type) of Integer
        := ((1, 2, 2, 1, 1),
            (1, 2, 1, 1, 1),
            (1, 1, 1, 2, 1));
      Max_Assembly_Content: constant array(Product_Type) of Integer := (3, 12, 3, 3, 3);
      Assembly_Number: array(Assembly_Type) of Integer
        := (1, 1, 1);
      In_Storage: Integer := 0;

      function Can_Accept(Product: Product_Type) return Boolean is
      begin
         if In_Storage < Storage_Capacity and Storage(Product) < Max_Assembly_Content(Product) then
            return True; -- Always accept a product if there's space
         else
            return False; -- Buffer is full
         end if;
      end Can_Accept;

      function Can_Deliver(Assembly: Assembly_Type) return Boolean is
      begin
         for W in Product_Type loop
            if Storage(W) < Assembly_Content(Assembly, W) then
               return False; -- Not enough products for the assembly
            end if;
         end loop;
         return True; -- Enough products for the assembly
      end Can_Deliver;

      procedure Storage_Contents is
      begin
         for W in Product_Type loop
            Put_Line("Storage contents: " & Integer'Image(Storage(W)) & " "
                     & Product_Name(W));
         end loop;
      end Storage_Contents;

   begin
      Put_Line("Buffer started");
      --Setup_Variables;
      loop
         accept Take(Product: in Product_Type; Number: in Integer; Taken: out Boolean) do
            if Can_Accept(Product) then
               Put_Line("Accepted product " & Product_Name(Product) & " number " &
                          Integer'Image(Number));
               Storage(Product) := Storage(Product) + 1;
               In_Storage := In_Storage + 1;
               Taken := true;
            else
               --Put_Line("Rejected product " & Product_Name(Product) & " number " & Integer'Image(Number));
               Taken := false;
            end if;
         end Take;
         Storage_Contents;
         accept Deliver(Assembly: in Assembly_Type; Number: out Integer; Delivered: out Boolean) do
            if Can_Deliver(Assembly) then
               Put_Line("Delivered assembly " & Assembly_Name(Assembly) & " number " &
                          Integer'Image(Assembly_Number(Assembly)));
               Delivered := true;
               for W in Product_Type loop
                  Storage(W) := Storage(W) - Assembly_Content(Assembly, W);
                  In_Storage := In_Storage - Assembly_Content(Assembly, W);
               end loop;
               Number := Assembly_Number(Assembly);
               Assembly_Number(Assembly) := Assembly_Number(Assembly) + 1;
            else
               Delivered := false;
               --Put_Line("Lacking products for assembly " & Assembly_Name(Assembly));
               --Number := 0;
            end if;
         end Deliver;
         delay 1.0;
      end loop;
   end Buffer;

begin
   for I in 1 .. Number_Of_Products loop
      P(I).Start(I, 10);
   end loop;
   for J in 1 .. Number_Of_Consumers loop
      K(J).Start(J,12);
   end loop;
end main;
