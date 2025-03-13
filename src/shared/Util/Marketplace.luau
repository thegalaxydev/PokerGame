local MarketplaceService = game:GetService("MarketplaceService")

export type ReceiptInfo = {
    PlayerId: number;
    PlaceIdWherePurchased: number;
    PurchaseId: string;
    ProductId: number;
    CurrencyType: Enum.CurrencyType;
    CurrencySpent: number;
}

local Util = {}

function Util.PlayerOwnsGamePassAsync(Player: Player, Pass: string): (boolean, boolean)
    local success, owns = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(Player.UserId, tonumber(Pass))
    end)

    return success, owns == true
end

return Util