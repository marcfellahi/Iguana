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

function Calculate_Value(ZITseg,UOM)

   local HighestValue = ZITseg[1][3]:nodeValue()
   local Qties = 1
   local UnitPrice = 0
   
   for i=1,#ZITseg[12] do

      if tonumber(ZITseg[12][i][2]:nodeValue()) ~= nil then
         Qties=Qties * ZITseg[12][i][2]:nodeValue()
      end
      
      if ZITseg[12][i][1] == UOM then
         break
      end
      
   end

   trace(HighestValue)
   if HighestValue == '' or HighestValue == nil then
      HighestValue = '0.00'
   end
   
   UnitPrice = tostring(round(HighestValue / Qties,4))
   UnitPrice = string.format("%.4f",UnitPrice)
   
   trace(UnitPrice,Qties)
   
   return UnitPrice
   
end

-- To parse XML use xml.parse{}
-- To query data from database use db.query{}
function MapData(Data,VmdFile)
   
   trace(Data)
   
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
         print('INCORRECT MSH SEGMENT: ',Msg,'\n',WarningMsg)
         return nil
         
      end
      
      trace(Name)

      ProcessInBound(Tables, Msg)
      return Tables

   end

end


function MapProduct(Table, ZIT, ZIN)
   
   local IUM, OUM, Value, ZITcounter 
   --trace('ZIT segment: ', ZIT[29], 'Description: ', ZIT[5])

   Table.CodeProduit = ZIT[29]
   Table.Description = ZIT[5]

   IUM   = ZIN[7]:nodeValue()
   
   trace(ZIN[12]:nodeValue()=='Y')
   
   if ZIN[12]:nodeValue() == 'Y' then
      OUM   = ZIN[7]:nodeValue()
   else
      OUM   = ZIN[6]:nodeValue()
   end

   Status = pcall(function () return tonumber(ZIT[12][1][3]:nodeValue()+0) end)
   trace(tonumber(ZIT[12][1][3]:nodeValue()))
   if Status then
      Value   = string.format("%.4f",(ZIT[12][1][3]:nodeValue() + 0))
   else
      Value   = Calculate_Value(ZIT,IUM)
   end
      
   QtyPack = Calculate_Qty(ZIT,IUM)

   Table.UniteAchat        = OUM   
   Table.UniteDistribution = IUM
   Table.UniteEmballage    = OUM
   Table.QteEmballage      = QtyPack
   Table.Valeur            = Value
   if ZIN[21]:nodeValue() == "N" then
      Table.Status = "N"
   else
      Table.Statut = "Y"
   end
   
   trace(ZIT[12][1][2],ZIN[12],Value, Table.Statut)

   return Table
   
end


function round(number, decimals)
    decimals = decimals or 0
    local factor = 10 ^ decimals
    return tonumber(("%."..decimals.."f"):format(number))
end

function MapProductSupplier(Table, ZIT, ZIN)
      
   Table.CodeProduitFournisseur = ZIT[1][2]
   
   return table
      
end
   
function MapSupplier(Table, ZIT, ZIN)
   
   trace(ZIT, ZIN)
   Table.CodeFournisseur = ZIT[1][1]
   Table.NomFournisseur= ZIN[32]
      
   return table
      
end


-- ##### Processing MAD (Admit/Discharge/Transfer) #####
function ProcessInBound(Tables, Msg)

   --print(Tables)
   MapProduct(Tables.Produit[1],Msg.ZIT, Msg.ZIN)
   MapProductSupplier(Tables.ProduitsFournisseurs[1],Msg.ZIT,Msg.ZIN)
   MapSupplier(Tables.Fournisseurs[1],Msg.ZIT,Msg.ZIN)
     
   return Tables
   
end