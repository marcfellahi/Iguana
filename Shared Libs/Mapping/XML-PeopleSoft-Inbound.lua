local function trace(a,b,c,d) return end

function Calculate_Qty(xml,UOM)

   local Qties = xml.PkgQty[1]
   
   return Qties
   
end

function Calculate_Value(xml,UOM)


   local UnitPrice  = 0
   if xml.PkgQty[1]:nodeValue()+0 <= 0 then
      conversion = 1
   else
      conversion = xml.PkgQty[1]:nodeValue()
   end
   --UnitPrice = tostring(round(xml.ProductValue[1]:nodeValue()/conversion,4)) 
   UnitPrice = tostring(round(xml.ProductValue[1]:nodeValue(),4))
   UnitPrice = string.format("%.4f",UnitPrice+0)
   
   trace(UnitPrice,Qties)
   
   --If UnitPrice < 0 then
     -- UnitPrice = 1
   --end
   
   return UnitPrice
   
end

-- To parse XML use xml.parse{}
-- To query data from database use db.query{}
function MapData(Data,VmdFile)
   
   if Data ~= '' then

      trace(VmdFile)
      
      local xmlData = xml.parse{data=Data}
      
      local Tables  = db.tables({vmd=VmdFile,name='Message'})
      
      trace(xmlData,Tables,Warnings)
      
      if Warnings ~= nil then
         
         local WarningMsg = ''
         
         for i=1,#Warnings do
         
            WarningMsg = WarningMsg..Warnings[i].description..'\n'
       
         end
         
         Message = Msg
         trace(WarningMsg)
         return nil
         
      end
      
      trace(jsonData)
      
      ProcessInBound(Tables, xmlData.ItemData)
      return Tables

   end

end


function MapProduct(Table, xml)
   
   local IUM, OUM, Value
   
   Table.CodeProduit = xml.Item[1]
   Table.Description = xml.Description[1]

   IUM   = xml.DistributionUnit[1]
   
   --if xml.Stock[1] == 'Y' then
   OUM   = xml.BuyingUnit[1]
   --else
      --OUM   = xml.DistributionUnit[1]
   --end

   trace(IUM,OUM)
   
   Value   = Calculate_Value(xml,IUM)
      
   QtyPack = Calculate_Qty(xml,IUM)

   Table.UniteAchat        = IUM   
   Table.UniteDistribution = IUM
   Table.UniteEmballage    = OUM
   Table.QteEmballage      = QtyPack
   Table.Valeur            = Value
   Table.Statut            = xml.ItemStatus[1]
  
   return Table
   
end


function MapProductSupplier(Table, xml)
      
   if xml.VendorItemID:childCount() == 0 then
      return ''
   end
   
   Table.CodeProduitFournisseur = xml.VendorItemID[1]
   
   return table
      
end
   
function MapSupplier(Table, xml)
   
   Table.CodeFournisseur = xml.Vendor[1]
   Table.NomFournisseur= ''
      
   return table
      
end


function ProcessInBound(Tables, Msg)

   MapProduct(Tables.Produit[1],Msg)
   MapProductSupplier(Tables.ProduitsFournisseurs[1],Msg)
   MapSupplier(Tables.Fournisseurs[1],Msg)
     
   return Tables
   
end

function Load_XML(Data)
   
end

function round(val, decimal)
  local exp = decimal and 10^decimal or 1
  return math.ceil(val * exp - 0.5) / exp
end