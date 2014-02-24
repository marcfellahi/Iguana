local function trace(a,b,c,d) return end

function Calculate_Qty(ZITseg,UOM)

   local Qties = 1
   
   for i=1,#ZITseg[12] do

      if tonumber(ZITseg[12][i][2]:nodeValue()) ~= nil then
         Qties=Qties * ZITseg[12][i][2]:nodeValue()
      end
      
      if ZITseg[12][i][1] == UOM then
         break
      end
      
   end
   
   return Qties
   
end

function Calculate_Value(ItemValue,CVFactor)

   local ConversionFactor = CVFactor
   local Value            = ItemValue
   
   UnitPrice = tonumber(Value:nodeValue())

   if UnitPrice == 0 then
      return ('0.0000')
   end
   
   UnitPrice = UnitPrice / CVFactor
   UnitPrice = string.format('%.4f',tostring(UnitPrice))
   
   return UnitPrice
   
end

function CheckIfNumber(value)
   
   value = value + 0
   return value
   
end

function ConvertValue(ItemValue)
   
   local Status, Result = pcall(CheckIfNumber,ItemValue)
   
   if Status then
      ItemValue = Result
   else
      ItemValue = 0
   end
   
   ItemValue = string.format('%.4f',tostring(ItemValue))
   
   return ItemValue
   
end
-- To parse XML use xml.parse{}
-- To query data from database use db.query{}
function MapData(Data,VmdFile)
   
   if Data ~= '' then
      
      local Msg,Name,Warnings = hl7.parse({vmd=VmdFile, data=Data})
      local Tables   = db.tables({vmd=VmdFile, name=Name})
      
      if Warnings ~= nil then
         
         local WarningMsg = ''
         
         for i=1,#Warnings do
         
            WarningMsg = WarningMsg..Warnings[i].description..'\n'
       
         end
         
         Message = Msg
         trace(WarningMsg)
         print('INCORRECT SEGMENT: ',Msg,'\n',WarningMsg)
         return nil
         
      end
      
      trace(Name)

      ProcessInBound(Tables, Msg)
      return Tables

   end

end


function MapProduct(Table, MSG)
   
   local IUM, OUM, Value, ZITcounter 
   --trace('ZIT segment: ', ZIT[29], 'Description: ', ZIT[5])

   trace(MSG)
   
   
   local Product = MSG.CD1[6]:nodeValue()
   local stock   = false
   
   if Product:sub(1,2) == 'NI' or Product:sub(1,3) == 'CON' then
      stock = true
   end
   
   Table.CodeProduit = MSG.CD1[3]
   Table.Description = MSG.CD1[2]

   trace(MSG)
   
   IUM = MSG.CD2[4]:nodeValue()   
   OUM = MSG.CD2[30]:nodeValue()
   
   QtyPack = MSG.CD2[31]:nodeValue() / MSG.CD2[5]:nodeValue()

   -- We use the Calculate_Value function with the value of 1 to avoid
   -- having returned values without a leading 0.  
   -- Marc Fellahi  2013/11/11
   Value = Calculate_Value(MSG.CD2[16],1)
   
   if stock then
      Table.UniteAchat = OUM
   else
      Table.UniteAchat = IUM
   end
   Table.UniteDistribution = IUM   
   Table.UniteEmballage    = OUM
   Table.QteEmballage      = QtyPack
   Table.UD3               = MSG.CD2[5]
   Table.Valeur            = Value

end
   
function MapProductSupplier(Table, MSG)
   
   Table.CodeProduitFournisseur = MSG.CD2[15]
   return table
      
end
   
function MapSupplier(Table, MSG)
   
   Table.CodeFournisseur = MSG.CD2[14][1]
   Table.NomFournisseur= MSG.CD2[14][2]
   return table
      
end


-- ##### Processing MAD (Admit/Discharge/Transfer) #####
function ProcessInBound(Tables, Msg)

   --print(Tables)
   MapProduct(Tables.Produit[1],Msg)
   MapProductSupplier(Tables.ProduitsFournisseurs[1],Msg)
   MapSupplier(Tables.Fournisseurs[1],Msg)
     
   return Tables
   
end