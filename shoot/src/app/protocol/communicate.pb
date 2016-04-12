
§U
communicate.protoprotocol
data.proto"
	Heartbeat
time ("j
ErrMsg)
errType (2.protocol.ErrMsg.ErrType
msg (	"(
ErrType
	EFloatTipË
EConfirmÈ"Õ
	RoleInfo_!
roleBase (2.protocol._Role
expBase (

hp (

mp (
atk (
def (
magDef (
crit (
critAdd	 (
dodge
 (
armor (
power ("è
	BagModify,

modifyType (2.protocol.BagModify.Type
item (2.protocol._Item"5
Type
Add

Delete

Update
ShowOnly"◊
InternalServer.
CreateRealm
realm (2.protocol._Realm!
CreateRealm_
	isSuccess (4
CreateChannel#
channel (2.protocol._Channel4
ChannelToRealm
	channelID (
realmID (
GetChannelArr8
GetChannelArr_&

channelArr (2.protocol._Channel
GetRealmArr2
GetRealmArr_"
realmArr (2.protocol._Realm
GetChannelToRealmJ
GetChannelToRealm_4
channelToRealmArr (2.protocol._ChannelToRealm<
SaveVIPInfo
RID (
VIPLevel (
VIPExp (8
AddItem
RID (
dataID (
quantity (
AddItem_
	isSuccess (,
RoleLevelUp
RID (
addLevel (!
RoleLevelUp_
	isSuccess (
UnlockAllDungeon
RID (&
UnlockAllDungeon_
	isSuccess (F
Recharge
	channelID (
UID (
RID (
money (
	Recharge_
	isSuccess ("ì
LoginServerS
Login
bind (
	channelID (
UUID (	
cname (	
CUID (	Æ
Login_
UID (1
realm (2".protocol.LoginServer.Login_.Realmd
Realm
realmID (
	realmName (	'
roleTypeArr (2.protocol.RoleType
status ("–G
SceneServerL

EnterRealm
realmID (
	channelID (
UUID (	
CUID (	¿
EnterRealm_7
roleArr (2&.protocol.SceneServer.EnterRealm_.Role
lastLoginRID (:-1^
Role
RID (
roleName (	
	roleLevel ($
roleType (2.protocol.RoleTypeU

CreateRole
realmID ($
roleType (2.protocol.RoleType
roleName (	
	EnterGame
RID (d

RoleDouble
RID ($
roleType (2.protocol.RoleType
roleName (	
	roleLevel (≠

EnterGame_%
roleInfo (2.protocol.RoleInfo_
bag (2.protocol._Bag%
worldMap (2.protocol._WorldMap4

roleDouble (2 .protocol.SceneServer.RoleDouble8
UpdateWorldMap_%
worldMap (2.protocol._WorldMap!
EnterDungeon
	dungeonID (I
EnterDungeon_
	bossItems (%
roleInfo (2.protocol.RoleInfo_Ê
ExitDungeon+
exitType (2.protocol.DungeonExitType

hp (H
mainTaskRecord (20.protocol.SceneServer.ExitDungeon.MainTaskRecordT
MainTaskRecord
taskID (2
progress (2 .protocol._MainTask.TaskProgress—
ExitDungeon_%
roleInfo (2.protocol.RoleInfo_;
eval (2-.protocol.SceneServer.ExitDungeon_.Evaluation!
gold (2.protocol.BagModify'

eliteItems (2.protocol.BagModify&
	bossItems (2.protocol.BagModify$
lotteryList (2.protocol._Item*
lotteryReward (2.protocol.BagModify%
worldMap (2.protocol._WorldMap
exp
 (‚

Evaluation
star (P
condSatisfy (2;.protocol.SceneServer.ExitDungeon_.Evaluation.EvalConditionS
condNotSatisfy (2;.protocol.SceneServer.ExitDungeon_.Evaluation.EvalConditionû
EvalConditionR
type (2D.protocol.SceneServer.ExitDungeon_.Evaluation.EvalCondition.EvalType
typeVal ("(
EvalType
HPRemain

DeathCount 
ArmorEnhance
uniqueID (4
ArmorEnhance_#
modify (2.protocol.BagModify$
ArmorRaiseDegree
uniqueID (8
ArmorRaiseDegree_#
modify (2.protocol.BagModify8
ReceiveStarReward
dungeonMapID (
index (9
ReceiveStarReward_#
modify (2.protocol.BagModify#
ImproveRoleSkill
skillID (&
ImproveRoleSkill_
	isSuccess (;
UpdateRoleSkill_'
	roleSkill (2.protocol._RoleSkill@
SaveSkillSetup.
setup (2.protocol._RoleSkill.SkillSetup$
SaveSkillSetup_
	isSuccess (
MainTaskDone
taskID ("
MainTaskDone_
	isSuccess (8
UpdateMainTask_%
mainTask (2.protocol._MainTask4

UpdateBag_&
	bagModify (2.protocol.BagModify
DailyTaskDone
taskID (#
DailyTaskDone_
	isSuccess (<
UpdateDailyTask_(

dailyTasks (2.protocol._DailyTask 
ActiveTaskDone
taskID ($
ActiveTaskDone_
	isSuccess (?
UpdateActiveTask_*
activeTasks (2.protocol._ActiveTaskY
WeaponEnhance
uniqueID (
talismanNum (!
material (2.protocol._ItemÄ
WeaponEnhance_
	isSuccess (/
enhancedItemModify (2.protocol.BagModify*
consumeModify (2.protocol.BagModify5
WeaponHardening
uniqueID (
material (r
WeaponHardening_2
hardeningedItemModify (2.protocol.BagModify*
consumeModify (2.protocol.BagModify8
WeaponSkillTransfer
uniqueID (
skillID (q
WeaponSkillTransfer_2
skillTransferedWeapon (2.protocol.BagModify%
consumes (2.protocol.BagModify%
AchievementTaskDone
taskID ()
AchievementTaskDone_
	isSuccess (˚
UpdateAchievementTask_
achievementTaskPoint (@
tasks (21.protocol.SceneServer.UpdateAchievementTask_.TaskÄ
Task
taskID (
progress (
time (
received (M
first (2>.protocol.SceneServer.UpdateAchievementTask_.Task.FirstReachedg
FirstReached$
roleType (2.protocol.RoleType
roleName (	
time (
	guildName (	.
	EquipItem
uniqueID (
equiped (

EquipItem_
	isSuccess (-

UpdateVIP_
VIPInfo (2.protocol._VIP
Alchemy
times (.
Alchemy_
	isSuccess (
critial (
UpdateAlchemy_
times (Z
AccessoryBaptize
targetUniqueID (
targetPosition (
sourceUniqueID (v
AccessoryBaptize_#
target (2.protocol.BagModify$
consume (2.protocol.BagModify
sourcePosition (+
AccessoryBaptizeRestore
uniqueID (e
AccessoryBaptizeRestore_#
target (2.protocol.BagModify$
consume (2.protocol.BagModifyC
AccessoryTransfer
targetUniqueID (
sourceUniqueID (d
AccessoryTransfer_(
accessories (2.protocol.BagModify$
consume (2.protocol.BagModify
	EnergyAdd

EnergyAdd_
	isSuccess (A
UpdateEnergy_
energy (
	countdown (
times (!
ResetDungeon
	dungeonID ("
ResetDungeon_
	isSuccess (6
UpdateDungeon_$
dungeons (2.protocol._Dungeon
ItemCompose
dataID ([
ItemCompose_%
composed (2.protocol.BagModify$
consume (2.protocol.BagModify
ItemUse
uniqueID (
ItemUse_
tip (	

ShopList
	ShopList_
	isSuccess (4
UpdateShopList_!
shops (2.protocol.ShopType,
ShopInfo 
shop (2.protocol.ShopType
	ShopInfo_
	isSuccess (±
UpdateShopInfo_$
shopType (2.protocol.ShopType
refreshTimestamp (
refreshTimes (:
goods (2+.protocol.SceneServer.UpdateShopInfo_.Goodsã
Goods
goodsID (B
item (24.protocol.SceneServer.UpdateShopInfo_.Goods.ItemInfo>
cost (20.protocol.SceneServer.UpdateShopInfo_.Goods.CostF
buyTimes (24.protocol.SceneServer.UpdateShopInfo_.Goods.BuyTimes
tip (	
discount (,
ItemInfo
dataID (
quantity ((
Cost
dataID (
quantity (.
BuyTimes
curTimes (
maxTimes (@
ShopBuy$
shopType (2.protocol.ShopType
goodsID (
ShopBuy_
	isSuccess (3
ShopRefresh$
shopType (2.protocol.ShopType!
ShopRefresh_
	isSuccess (z
	SellItems=
saleItemArr (2(.protocol.SceneServer.SellItems.SaleItem.
SaleItem
uniqueID (
quantity (

SellItems_
	isSuccess (
ConjureHero
heroID (!
ConjureHero_
	isSuccess (

InviteHero
heroID ( 
InviteHero_
	isSuccess (
DismissHero
heroID (!
DismissHero_
	isSuccess (@
HeroUseItem
uniqueID (
heroID (
itemNUM (1
HeroUseItem_
heroID (
	isSuccess (
HeroQualityUp
heroID (3
HeroQualityUp_
heroID (
	isSuccess (

HeroStarUp
heroID (0
HeroStarUp_
heroID (
	isSuccess (®
UpdateFightHero_B
	heroInfos (2/.protocol.SceneServer.UpdateFightHero_.HeroInfoP
HeroInfo 
heroBase (2.protocol.hero"
props (2.protocol.heroProps&
SecretEnter
secretDungeonID (!
SecretEnter_
	isSuccess (Ñ

SecretExit+
exitType (2.protocol.DungeonExitType
secretDungeonID (
damage (
drops (
	spacetime ( 
SecretExit_
	isSuccess (
	SecretBuy
secretID (

SecretBuy_
	isSuccess (3
UpdateSecret_"
secrets (2.protocol._Secret=
StartSecretWeaponMap
secretID (
weaponMapID (*
StartSecretWeaponMap_
	isSuccess (>
GiveupSecretWeaponMap
secretID (
weaponMapID (+
GiveupSecretWeaponMap_
	isSuccess (=
SweepSecretWeaponMap
secretID (
weaponMapID (*
SweepSecretWeaponMap_
	isSuccess (J
!RecieveSecretWeaponMapSweepReward
secretID (
weaponMapID (7
"RecieveSecretWeaponMapSweepReward_
	isSuccess (1
HeroLoadBadge
heroID (
uniqueID (#
HeroLoadBadge_
	isSuccess (!
HeroUnloadBadge
heroID (%
HeroUnloadBadge_
	isSuccess (C
HeroInlayBadge
uniqueID (
slot (
	crystalID ($
HeroInlayBadge_
	isSuccess ("
BadgeQualityUp
uniqueID ($
BadgeQualityUp_
	isSuccess (4
PlaceToConstellation
heroID (
seat (*
PlaceToConstellation_
	isSuccess ((
KickoutFromConstellation
seat (.
KickoutFromConstellation_
	isSuccess (%
ReceiveVIPRewards
VIPLevel ('
ReceiveVIPRewards_
	isSuccess (2
UpdateFashion_ 
fashion (2.protocol._Item0
SweepDungeon
	dungeonID (
times ("
SweepDungeon_
	isSuccess (#
TravelTimewheel
secretID (%
TravelTimewheel_
	isSuccess (0
RecieveTravelTimewheelReward
secretID (2
RecieveTravelTimewheelReward_
	isSuccess (÷
	_RoleMail
mailName (	
mailDate (
mailContent (	>

attachment (2*.protocol.SceneServer._RoleMail.Attachment
mailID (
readTime (.

Attachment
dataID (
quantity (=
UpdateMail_.
mails (2.protocol.SceneServer._RoleMail
MailReceive
mailID (!
MailReceive_
	isSuccess (8
RankList,
type (2.protocol.SceneServer.RankTypeÛ
	RankList_,
type (2.protocol.SceneServer.RankType;
players (2*.protocol.SceneServer.RankList_.PlayerInfo

updateTime (g

PlayerInfo
RID ( 
type (2.protocol.RoleType
name (	
power (
level (" 
RankType	
Power	
Level"
DungeonServer*<
DungeonExitType
Win
Dead
Timeover
Quit