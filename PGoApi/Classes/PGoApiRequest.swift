//
//  PgoApi.swift
//  pgomap
//
//  Based on https://github.com/tejado/pgoapi/blob/master/pgoapi/pgoapi.py
//
//  Created by Luke Sapan on 7/20/16.
//  Copyright © 2016 Coadstal. All rights reserved.
//

import Foundation
import ProtocolBuffers


public struct ApiMethod {
    let id: Pogoprotos.Networking.Requests.RequestType
    let message: GeneratedMessage
    let parser: NSData -> GeneratedMessage
}

public struct ApiResponse {
    public let response: GeneratedMessage
    public let subresponses: [GeneratedMessage]
}

public class PGoApiRequest {
    public var methodList: [ApiMethod] = []
    
    public init() {
        
    }

    public func makeRequest(intent: ApiIntent, delegate: PGoApiDelegate?) {  // analogous to call in pgoapi.py
        if methodList.count == 0 {
            print("makeRequest() called without any methods in methodList.")
            return
        }
        
        if !PGoAuth.sharedInstance.loggedIn {
            print("makeRequest() called without being logged in.")
            return
        }
        
        // TODO: Get player position
        // position stuff here...
        let request = RpcApi(subrequests: methodList, intent: intent, delegate: delegate)
        request.request(Api.endpoint)
    }
    
    public func simulateAppStart() {
        getPlayer()
        getHatchedEggs()
        getInventory()
        checkAwardedBadges()
        downloadSettings()
    }
    
    public func updatePlayer() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.PlayerUpdateMessage.Builder()
        messageBuilder.latitude = Location.lat
        messageBuilder.longitude = Location.long
        methodList.append(ApiMethod(id: .PlayerUpdate, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.PlayerUpdateResponse.parseFromData(data)
        }))
    }
    
    public func getPlayer() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetPlayerMessage.Builder()
        methodList.append(ApiMethod(id: .GetPlayer, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetPlayerResponse.parseFromData(data)
        }))
    }
    
    public func getInventory(lastTimestampMs: Int64? = nil) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetInventoryMessage.Builder()
        if lastTimestampMs != nil {
            messageBuilder.lastTimestampMs = lastTimestampMs!
        }
        methodList.append(ApiMethod(id: .GetInventory, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetInventoryResponse.parseFromData(data)
        }))
    }
    
    public func downloadSettings() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.DownloadSettingsMessage.Builder()
        messageBuilder.hash = Api.SettingsHash
        methodList.append(ApiMethod(id: .DownloadSettings, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.DownloadSettingsResponse.parseFromData(data)
        }))
    }
    
    public func downloadItemTemplates() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.DownloadItemTemplatesMessage.Builder()
        methodList.append(ApiMethod(id: .DownloadItemTemplates, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.DownloadItemTemplatesResponse.parseFromData(data)
        }))
    }
    
    public func downloadRemoteConfigVersion(deviceModel: String, deviceManufacturer: String, locale: String, appVersion: UInt32) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.DownloadRemoteConfigVersionMessage.Builder()
        messageBuilder.platform = .Ios
        messageBuilder.deviceModel = deviceModel
        messageBuilder.deviceManufacturer = deviceManufacturer
        messageBuilder.locale = locale
        messageBuilder.appVersion = appVersion
        methodList.append(ApiMethod(id: .DownloadRemoteConfigVersion, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.DownloadRemoteConfigVersionResponse.parseFromData(data)
        }))
    }
    
    public func fortSearch(fortId: String, fortLatitude: Double, fortLongitude: Double) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.FortSearchMessage.Builder()
        messageBuilder.fortId = fortId
        messageBuilder.fortLatitude = fortLatitude
        messageBuilder.fortLongitude = fortLongitude
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        methodList.append(ApiMethod(id: .FortSearch, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.FortSearchResponse.parseFromData(data)
        }))
    }
    
    public func encounterPokemon(encounterId: UInt64, spawnPointId: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.EncounterMessage.Builder()
        messageBuilder.encounterId = encounterId
        messageBuilder.spawnPointId = spawnPointId
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        methodList.append(ApiMethod(id: .Encounter, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.EncounterResponse.parseFromData(data)
        }))
    }
    
    public func catchPokemon(encounterId: UInt64, spawnPointId: String, pokeball: Pogoprotos.Inventory.Item.ItemId, hitPokemon: Bool, normalizedReticleSize: Double, normalizedHitPosition: Double, spinModifier: Double) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.CatchPokemonMessage.Builder()
        messageBuilder.encounterId = encounterId
        messageBuilder.spawnPointId = spawnPointId
        messageBuilder.pokeball = pokeball
        messageBuilder.hitPokemon = hitPokemon
        messageBuilder.normalizedReticleSize = normalizedReticleSize
        messageBuilder.normalizedHitPosition = normalizedHitPosition
        messageBuilder.spinModifier = spinModifier
        
        methodList.append(ApiMethod(id: .CatchPokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.CatchPokemonResponse.parseFromData(data)
        }))
    }
    
    public func fortDetails(fortId: String, fortLatitude: Double, fortLongitude: Double) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.FortDetailsMessage.Builder()
        messageBuilder.fortId = fortId
        messageBuilder.latitude = fortLatitude
        messageBuilder.longitude = fortLongitude
        methodList.append(ApiMethod(id: .FortDetails, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.FortDetailsResponse.parseFromData(data)
        }))
    }
    
    public func generateS2Cells(lat: Double, long: Double) -> Array<UInt64> {
        let cell = S2CellId(p: S2LatLon(latDegrees: lat, lonDegrees: long).toPoint())
        var cells: [UInt64] = []
        
        var currentCell = cell
        for _ in 0..<10 {
            currentCell = currentCell.prev()
            cells.insert(currentCell.id, atIndex: 0)
        }
        
        cells.append(cell.id)
        
        currentCell = cell
        for _ in 0..<10 {
            currentCell = currentCell.next()
            cells.append(currentCell.id)
        }
        return cells
    }
    
    public func getMapObjects(cellIds: Array<UInt64>? = nil, sinceTimestampMs: Array<Int64>? = nil) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetMapObjectsMessage.Builder()
        messageBuilder.latitude = Location.lat
        messageBuilder.longitude = Location.long
        
        if sinceTimestampMs != nil {
            messageBuilder.sinceTimestampMs = sinceTimestampMs!
        } else {
            var timeStamps: Array<Int64> = []
            if cellIds != nil {
                for _ in cellIds! {
                    timeStamps.append(0)
                }
                messageBuilder.sinceTimestampMs = timeStamps
            } else {
                messageBuilder.sinceTimestampMs = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
            }
        }
        
        if cellIds != nil {
            messageBuilder.cellId = cellIds!
            
        } else {
            let cells = generateS2Cells(Location.lat, long: Location.long)
            messageBuilder.cellId = cells
        }
        
        methodList.append(ApiMethod(id: .GetMapObjects, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetMapObjectsResponse.parseFromData(data)
        }))
    }
    
    public func fortDeployPokemon(fortId: String, pokemonId:UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.FortDeployPokemonMessage.Builder()
        messageBuilder.fortId = fortId
        messageBuilder.pokemonId = pokemonId
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        methodList.append(ApiMethod(id: .FortDeployPokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.FortDeployPokemonResponse.parseFromData(data)
        }))
    }
    
    public func fortRecallPokemon(fortId: String, pokemonId:UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.FortRecallPokemonMessage.Builder()
        messageBuilder.fortId = fortId
        messageBuilder.pokemonId = pokemonId
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        methodList.append(ApiMethod(id: .FortRecallPokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.FortRecallPokemonResponse.parseFromData(data)
        }))
    }
    
    public func releasePokemon(pokemonId:UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.ReleasePokemonMessage.Builder()
        messageBuilder.pokemonId = pokemonId
        methodList.append(ApiMethod(id: .ReleasePokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.ReleasePokemonResponse.parseFromData(data)
        }))
    }
    
    public func useItemPotion(itemId: Pogoprotos.Inventory.Item.ItemId, pokemonId:UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.UseItemPotionMessage.Builder()
        messageBuilder.itemId = itemId
        messageBuilder.pokemonId = pokemonId
        methodList.append(ApiMethod(id: .UseItemPotion, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.UseItemPotionResponse.parseFromData(data)
        }))
    }
    
    public func useItemCapture(itemId: Pogoprotos.Inventory.Item.ItemId, encounterId:UInt64, spawnPointId: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.UseItemCaptureMessage.Builder()
        messageBuilder.itemId = itemId
        messageBuilder.encounterId = encounterId
        messageBuilder.spawnPointId = spawnPointId
        methodList.append(ApiMethod(id: .UseItemCapture, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.UseItemCaptureResponse.parseFromData(data)
        }))
    }
    
    public func useItemRevive(itemId: Pogoprotos.Inventory.Item.ItemId, pokemonId: UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.UseItemReviveMessage.Builder()
        messageBuilder.itemId = itemId
        messageBuilder.pokemonId = pokemonId
        methodList.append(ApiMethod(id: .UseItemRevive, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.UseItemReviveResponse.parseFromData(data)
        }))
    }
    
    public func getPlayerProfile(playerName: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetPlayerProfileMessage.Builder()
        messageBuilder.playerName = playerName
        methodList.append(ApiMethod(id: .GetPlayerProfile, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetPlayerProfileResponse.parseFromData(data)
        }))
    }
    
    public func evolvePokemon(pokemonId: UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.EvolvePokemonMessage.Builder()
        messageBuilder.pokemonId = pokemonId
        methodList.append(ApiMethod(id: .EvolvePokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.EvolvePokemonResponse.parseFromData(data)
        }))
    }
    
    public func getHatchedEggs() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetHatchedEggsMessage.Builder()
        methodList.append(ApiMethod(id: .GetHatchedEggs, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetHatchedEggsResponse.parseFromData(data)
        }))
    }
    
    public func encounterTutorialComplete(pokemonId: Pogoprotos.Enums.PokemonId) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.EncounterTutorialCompleteMessage.Builder()
        messageBuilder.pokemonId = pokemonId
        methodList.append(ApiMethod(id: .EncounterTutorialComplete, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.EncounterTutorialCompleteResponse.parseFromData(data)
        }))
    }
    
    public func levelUpRewards(level:Int32) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.LevelUpRewardsMessage.Builder()
        messageBuilder.level = level
        methodList.append(ApiMethod(id: .LevelUpRewards, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.LevelUpRewardsResponse.parseFromData(data)
        }))
    }
    
    public func checkAwardedBadges() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.CheckAwardedBadgesMessage.Builder()
        methodList.append(ApiMethod(id: .CheckAwardedBadges, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.CheckAwardedBadgesResponse.parseFromData(data)
        }))
    }
    
    public func useItemGym(itemId: Pogoprotos.Inventory.Item.ItemId, gymId: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.UseItemGymMessage.Builder()
        messageBuilder.itemId = itemId
        messageBuilder.gymId = gymId
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        methodList.append(ApiMethod(id: .UseItemGym, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.UseItemGymResponse.parseFromData(data)
        }))
    }
    
    public func getGymDetails(gymId: String, gymLatitude: Double, gymLongitude: Double) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetGymDetailsMessage.Builder()
        messageBuilder.gymId = gymId
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        messageBuilder.gymLatitude = gymLatitude
        messageBuilder.gymLongitude = gymLongitude
        methodList.append(ApiMethod(id: .GetGymDetails, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetGymDetailsResponse.parseFromData(data)
        }))
    }
    
    public func startGymBattle(gymId: String, attackingPokemonIds: Array<UInt64>, defendingPokemonId: UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.StartGymBattleMessage.Builder()
        messageBuilder.gymId = gymId
        messageBuilder.attackingPokemonIds = attackingPokemonIds
        messageBuilder.defendingPokemonId = defendingPokemonId
        methodList.append(ApiMethod(id: .StartGymBattle, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.StartGymBattleResponse.parseFromData(data)
        }))
    }
    
    public func attackGym(gymId: String, battleId: String, attackActions: Array<Pogoprotos.Data.Battle.BattleAction>, lastRetrievedAction: Pogoprotos.Data.Battle.BattleAction) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.AttackGymMessage.Builder()
        messageBuilder.gymId = gymId
        messageBuilder.battleId = battleId
        messageBuilder.attackActions = attackActions
        messageBuilder.lastRetrievedActions = lastRetrievedAction
        messageBuilder.playerLongitude = Location.lat
        messageBuilder.playerLatitude = Location.long
        
        methodList.append(ApiMethod(id: .AttackGym, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.AttackGymResponse.parseFromData(data)
        }))
    }
    
    public func recycleInventoryItem(itemId: Pogoprotos.Inventory.Item.ItemId, itemCount: Int32) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.RecycleInventoryItemMessage.Builder()
        messageBuilder.itemId = itemId
        messageBuilder.count = itemCount
        methodList.append(ApiMethod(id: .RecycleInventoryItem, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.RecycleInventoryItemResponse.parseFromData(data)
        }))
    }
    
    public func collectDailyBonus() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.CollectDailyBonusMessage.Builder()
        methodList.append(ApiMethod(id: .CollectDailyBonus, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.CollectDailyBonusResponse.parseFromData(data)
        }))
    }
    
    public func useItemXPBoost(itemId: Pogoprotos.Inventory.Item.ItemId) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.UseItemXpBoostMessage.Builder()
        messageBuilder.itemId = itemId
        methodList.append(ApiMethod(id: .UseItemXpBoost, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.UseItemXpBoostResponse.parseFromData(data)
        }))
    }
    
    public func useItemEggIncubator(itemId: String, pokemonId: UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.UseItemEggIncubatorMessage.Builder()
        messageBuilder.itemId = itemId
        messageBuilder.pokemonId = pokemonId
        methodList.append(ApiMethod(id: .UseItemEggIncubator, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.UseItemEggIncubatorResponse.parseFromData(data)
        }))
    }
    
    public func useIncense(itemId: Pogoprotos.Inventory.Item.ItemId) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.UseIncenseMessage.Builder()
        messageBuilder.incenseType = itemId
        methodList.append(ApiMethod(id: .UseIncense, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.UseIncenseResponse.parseFromData(data)
        }))
    }
    
    public func getIncensePokemon() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetIncensePokemonMessage.Builder()
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        methodList.append(ApiMethod(id: .GetIncensePokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetIncensePokemonResponse.parseFromData(data)
        }))
    }
    
    public func incenseEncounter(encounterId: Int64, encounterLocation: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.IncenseEncounterMessage.Builder()
        messageBuilder.encounterId = encounterId
        messageBuilder.encounterLocation = encounterLocation
        methodList.append(ApiMethod(id: .IncenseEncounter, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.IncenseEncounterResponse.parseFromData(data)
        }))
    }
    
    public func addFortModifier(itemId: Pogoprotos.Inventory.Item.ItemId, fortId: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.AddFortModifierMessage.Builder()
        messageBuilder.modifierType = itemId
        messageBuilder.fortId = fortId
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        methodList.append(ApiMethod(id: .AddFortModifier, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.AddFortModifierResponse.parseFromData(data)
        }))
    }
    
    public func diskEncounter(encounterId: UInt64, fortId: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.DiskEncounterMessage.Builder()
        messageBuilder.encounterId = encounterId
        messageBuilder.fortId = fortId
        messageBuilder.playerLatitude = Location.lat
        messageBuilder.playerLongitude = Location.long
        methodList.append(ApiMethod(id: .DiskEncounter, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.DiskEncounterResponse.parseFromData(data)
        }))
    }
    
    public func collectDailyDefenderBonus(encounterId: UInt64, fortId: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.CollectDailyDefenderBonusMessage.Builder()
        methodList.append(ApiMethod(id: .CollectDailyDefenderBonus, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.CollectDailyDefenderBonusResponse.parseFromData(data)
        }))
    }
    
    public func upgradePokemon(pokemonId: UInt64) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.UpgradePokemonMessage.Builder()
        messageBuilder.pokemonId = pokemonId
        methodList.append(ApiMethod(id: .UpgradePokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.UpgradePokemonResponse.parseFromData(data)
        }))
    }
    
    public func setFavoritePokemon(pokemonId: UInt64, isFavorite: Bool) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.SetFavoritePokemonMessage.Builder()
        messageBuilder.pokemonId = pokemonId
        messageBuilder.isFavorite = isFavorite
        methodList.append(ApiMethod(id: .SetFavoritePokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.SetFavoritePokemonResponse.parseFromData(data)
        }))
    }
    
    public func nicknamePokemon(pokemonId: UInt64, nickname: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.NicknamePokemonMessage.Builder()
        messageBuilder.pokemonId = pokemonId
        messageBuilder.nickname = nickname
        methodList.append(ApiMethod(id: .NicknamePokemon, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.NicknamePokemonResponse.parseFromData(data)
        }))
    }
    
    public func equipBadge(badgeType: Pogoprotos.Enums.BadgeType) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.EquipBadgeMessage.Builder()
        messageBuilder.badgeType = badgeType
        methodList.append(ApiMethod(id: .EquipBadge, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.EquipBadgeResponse.parseFromData(data)
        }))
    }
    
    public func setContactSettings(sendMarketingEmails: Bool, sendPushNotifications: Bool) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.SetContactSettingsMessage.Builder()
        let contactSettings = Pogoprotos.Data.Player.ContactSettings.Builder()
        contactSettings.sendMarketingEmails = sendMarketingEmails
        contactSettings.sendPushNotifications = sendPushNotifications
        try! messageBuilder.contactSettings = contactSettings.build()
        methodList.append(ApiMethod(id: .SetContactSettings, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.SetContactSettingsResponse.parseFromData(data)
        }))
    }
    
    public func getAssetDigest(deviceModel: String, deviceManufacturer: String, locale: String, appVersion: UInt32) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetAssetDigestMessage.Builder()
        messageBuilder.platform = .Ios
        messageBuilder.deviceModel = deviceModel
        messageBuilder.deviceManufacturer = deviceManufacturer
        messageBuilder.locale = locale
        messageBuilder.appVersion = appVersion
        methodList.append(ApiMethod(id: .GetAssetDigest, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetAssetDigestResponse.parseFromData(data)
        }))
    }
    
    public func getDownloadURLs(assetId: Array<String>) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetDownloadUrlsMessage.Builder()
        messageBuilder.assetId = assetId
        methodList.append(ApiMethod(id: .GetDownloadUrls, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetDownloadUrlsResponse.parseFromData(data)
        }))
    }
    
    public func getSuggestedCodenames() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.GetSuggestedCodenamesMessage.Builder()
        methodList.append(ApiMethod(id: .GetSuggestedCodenames, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.GetSuggestedCodenamesResponse.parseFromData(data)
        }))
    }
    
    public func checkCodenameAvailable(codename: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.CheckCodenameAvailableMessage.Builder()
        messageBuilder.codename = codename
        methodList.append(ApiMethod(id: .CheckCodenameAvailable, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.CheckCodenameAvailableResponse.parseFromData(data)
        }))
    }
    
    public func claimCodename(codename: String) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.ClaimCodenameMessage.Builder()
        messageBuilder.codename = codename
        methodList.append(ApiMethod(id: .ClaimCodename, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.ClaimCodenameResponse.parseFromData(data)
        }))
    }
    
    public func setAvatar(skin: Int32, hair: Int32, shirt: Int32, pants: Int32, hat: Int32, shoes: Int32, gender: Pogoprotos.Enums.Gender, eyes: Int32, backpack: Int32) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.SetAvatarMessage.Builder()
        
        let playerAvatar = Pogoprotos.Data.Player.PlayerAvatar.Builder()
        playerAvatar.backpack = backpack
        playerAvatar.skin = skin
        playerAvatar.hair = hair
        playerAvatar.shirt = shirt
        playerAvatar.pants = pants
        playerAvatar.hat = hat
        playerAvatar.gender = gender
        playerAvatar.eyes = eyes
        
        try! messageBuilder.playerAvatar = playerAvatar.build()
        
        methodList.append(ApiMethod(id: .SetAvatar, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.SetAvatarResponse.parseFromData(data)
        }))
    }
    
    public func setPlayerTeam(teamColor: Pogoprotos.Enums.TeamColor) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.SetPlayerTeamMessage.Builder()
        messageBuilder.team = teamColor
        methodList.append(ApiMethod(id: .SetPlayerTeam, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.SetPlayerTeamResponse.parseFromData(data)
        }))
    }
    
    public func markTutorialComplete(tutorialState: Array<Pogoprotos.Enums.TutorialState>, sendMarketingEmails: Bool, sendPushNotifications: Bool) {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.MarkTutorialCompleteMessage.Builder()
        messageBuilder.tutorialsCompleted = tutorialState
        messageBuilder.sendMarketingEmails = sendMarketingEmails
        messageBuilder.sendPushNotifications = sendPushNotifications
        methodList.append(ApiMethod(id: .MarkTutorialComplete, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.MarkTutorialCompleteResponse.parseFromData(data)
        }))
    }
    
    public func echo() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.EchoMessage.Builder()
        methodList.append(ApiMethod(id: .Echo, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.EchoResponse.parseFromData(data)
        }))
    }
    
    public func sfidaActionLog() {
        let messageBuilder = Pogoprotos.Networking.Requests.Messages.SfidaActionLogMessage.Builder()
        methodList.append(ApiMethod(id: .SfidaActionLog, message: try! messageBuilder.build(), parser: { data in
            return try! Pogoprotos.Networking.Responses.SfidaActionLogResponse.parseFromData(data)
        }))
    }
}