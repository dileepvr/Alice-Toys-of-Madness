class ToM_Ammo : Ammo
{
	mixin ToM_CheckParticles;
	mixin ToM_PickupFlashProperties;
	mixin ToM_PickupSound;
	mixin ToM_ComplexPickupmessage;
	
	class<Ammo> bigPickupClass;
	property bigPickupClass : bigPickupClass;
	
	Default 
	{
		xscale 0.4;
		yscale 0.33334;
		+BRIGHT
		+RANDOMIZE
		FloatBobStrength 0.65;
		Inventory.pickupsound "pickups/ammo";
	}

	override Class<Ammo> GetParentAmmo ()
	{
		class<Object> type = GetClass();

		while (type.GetParentClass() && type.GetParentClass() != "Ammo" && type.GetParentClass() != "ToM_Ammo")
		{
			type = type.GetParentClass();
		}
		return (class<Ammo>)(type);
	}
	
	override void PostBeginPlay()
	{
		super.PostBeginPlay();
		A_SpriteOffset (0, -24);
	}
	
	override void Tick()
	{
		super.Tick();
		if (owner || isFrozen())
			return;
		
		WorldOffset.z = BobSin(FloatBobPhase + 0.85 * level.maptime) * FloatBobStrength;
	}
}

class ToM_WeakMana : ToM_Ammo
{
	Default
	{
		Inventory.pickupmessage "$TOM_MANA_WEAK";
		inventory.amount 10;
		inventory.maxamount 300;
		ammo.backpackamount 100;
		ammo.backpackmaxamount 300;
		ToM_Ammo.bigPickupClass "ToM_WeakManaBig";
	}
	
	override string GetPickupNote()
	{
		return String.Format("+%d", amount);
	}
	
	States {
	Spawn:
		AMWS A 15;
		AMWS BCDEFGHI 3;
		loop;
	}
}

class ToM_WeakManaBig : ToM_WeakMana
{
	Default
	{
		inventory.amount 40;
		ToM_Ammo.bigPickupClass "";
	}
	
	States {
	Spawn:
		AMWB A 15;
		AMWB BCDEFGHIJKL 2;
		loop;
	}
}

// haha it's actually green by default
class ToM_MediumMana : ToM_Ammo
{
	Default
	{
		Inventory.pickupmessage "$TOM_MANA_MEDIUM";
		inventory.amount 25;
		inventory.maxamount 300;
		ammo.backpackamount 100;
		ammo.backpackmaxamount 300;
		ToM_Ammo.bigPickupClass "ToM_MediumManaBig";
	}
	
	override string GetPickupNote()
	{
		return String.Format("+%d", amount);
	}
	
	States {
	Spawn:
		AMMS A 15;
		AMMS BCDEFGHIJKL 2;
		loop;
	}
}

class ToM_MediumManaBig : ToM_MediumMana
{
	Default
	{
		inventory.amount 60;
		ToM_Ammo.bigPickupClass "";
	}
	
	States {
	Spawn:
		AMMB A 15;
		AMMB BCDEFGHIJKL 2;
		loop;
	}
}

class ToM_StrongMana : ToM_Ammo
{
	Default
	{
		Inventory.pickupmessage "$TOM_MANA_STRONG";
		inventory.amount 10;
		inventory.maxamount 300;
		ammo.backpackamount 100;
		ammo.backpackmaxamount 300;
		ToM_Ammo.bigPickupClass "ToM_StrongManaBig";
	}
	
	override string GetPickupNote()
	{
		return String.Format("+%d", amount);
	}
	
	States {
	Spawn:
		AMSS A 15;
		AMSS BCDEFGHI 3;
		loop;
	}
}

class ToM_StrongManaBig : ToM_StrongMana
{
	Default
	{
		inventory.amount 40;
		ToM_Ammo.bigPickupClass "";
	}
	
	States {
	Spawn:
		AMSB A 15;
		AMSB BCDEFGHIJKL 2;
		loop;
	}
}


/////////////////////
/// AMMO SPAWNERS ///
/////////////////////

class ToM_EquipmentSpawner : Inventory 
{
	Class<Ammo> ammo1; //ammo type for the 1st weapon
	Class<Ammo> ammo2; //ammo type for the 2nd weapon
	Class<Weapon> weapon1; //1st weapon class to spawn ammo for
	Class<Weapon> weapon2; //2nd weapon class to spawn ammo for
	// chance of spawning ammo for weapon2 instead of weapon1:
	double otherPickupChance;
	// chance of spawning the big ammo pickup instead of the small one:
	double bigPickupChance;
	// chance of spawning the second ammotype next to 
	// the one chosen to be spawned:
	double twoPickupsChance;	
	// chance that this will be obtainable 
	// if dropped by an enemy:
	double dropChance;
	
	property weapon1 : weapon1;
	property weapon2 : weapon2;
	property otherPickupChance : otherPickupChance;
	property bigPickupChance : bigPickupChance;
	property twoPickupsChance : twoPickupsChance;
	property dropChance : dropChance;

	Default 
	{
		+NOBLOCKMAP
		-SPECIAL
		ToM_EquipmentSpawner.otherPickupChance 50;
		ToM_EquipmentSpawner.bigPickupChance 25;
		ToM_EquipmentSpawner.twoPickupsChance 0;
		ToM_EquipmentSpawner.dropChance 100;
	}
	
	Inventory SpawnInvPickup(vector3 spawnpos, Class<Inventory> ammopickup) 
	{
		let toSpawn = ammopickup;
		
		if (bigPickupChance >= 1)
		{
			let am = (class<ToM_Ammo>)(ammopickup);
			if (am)
			{
				let bigPickupCls = GetDefaultByType(am).bigPickupClass;
				if (bigPickupCls && bigPickupChance >= frandom[ammoSpawn](1,100))
				{
					toSpawn = bigPickupCls;
				}
			}
		}
		
		let inv = Inventory(Spawn(toSpawn,spawnpos));
		
		if (inv) 
		{
			inv.vel = vel;
			// Halve the amount if it's dropped by the enemy:
			if (bTOSSED) 
			{
				inv.bTOSSED = true;
				inv.amount = Clamp(inv.amount / 2, 1, inv.amount);
			}
			
			// this is important to make sure that the weapon 
			// that wasn't dropped doesn't get DROPPED flag 
			// (and thus can't be crushed by moving ceilings)
			else
				inv.bDROPPED = false;
		}
		return inv;
	}
	
	// returns true if any of the players have the weapon, 
	// or if the weapon exists on the current map:
	bool CheckExistingWeapons(Class<Weapon> checkWeapon) 
	{
		//check players' inventories:
		if (ToM_UtilsP.CheckPlayersHave(checkWeapon))
			return true;
			
		//check the array that contains all spawned weapon classes:
		ToM_MainHandler handler = ToM_MainHandler(EventHandler.Find("ToM_MainHandler"));
		if (handler && handler.mapweapons.Find(checkWeapon) != handler.mapweapons.Size())
			return true;

		return false;
	}
	
	States {
	Spawn:
		TNT1 A 0 NoDelay
		{
			// weapon1 is obligatory; if for whatever 
			// reason it's empty, destroy it:
			if (!weapon1) 
			{
				Destroy();
				return;
			}	
			
			// if dropped by an enemy, the pickusp aren't
			// guaranteed to spawn:
			if (bTOSSED && dropChance < frandom[ammoSpawn](1,100)) 
			{
				Destroy();
				return;
			}
			
			//get ammo classes for weapon1 and weapon2:
			ammo1 = GetDefaultByType(weapon1).ammotype1;
			
			if (weapon2) 
			{
				ammo2 = GetDefaultByType(weapon2).ammotype1;
				// if none of the players have weapon1 and it 
				// doesn't exist on the map, increase the chance 
				// of spawning ammo for weapon2:
				if (!CheckExistingWeapons(weapon1))
					otherPickupChance *= 1.5;
				// if none of the players have weapon2 and it 
				// doesn't exist on the map, decreate the chance 
				// of spawning ammo for weapon2:
				if (!CheckExistingWeapons(weapon2))
					otherPickupChance /= 1.5;
				// if players have neither, both calculations 
				// will happen, ultimately leaving the chance 
				// unchanged!
				if (tom_debugmessages > 1)
					console.printf("alt set chance: %f",otherPickupChance);
			}
			
			//define two possible ammo pickups to spawn:
			class<Ammo> tospawn = ammo1;
			
			//with a chance they'll be replaced with ammo for weapon2:
			if (weapon2 && otherPickupChance >= random[ammoSpawn](1,100)) 
			{
				tospawn = ammo2;
			}
			
			//ammo dropped by enemies should always be small:
			if (bTOSSED)
			{
				bigPickupChance = 0;
			}
			
			// Spawn the ammo:
			SpawnInvPickup(pos,tospawn);
			
			// if the chance for two pickups is high enough, 
			// spawn the other type of ammo:
			if (twoPickupsChance >= frandom[ammoSpawn](1,100)) {
				class<Ammo> tospawn2 = (tospawn == ammo1) ? ammo2 : ammo1;
				// If it's dropped by an enemy, throw the second
				// pickup at a different angle:
				if (bTOSSED)
				{
					let a = SpawnInvPickup(pos,tospawn2);
					if (a)
					{
						a.vel = vel;
						int d = randompick[ammoSpawn](-1, 1);
						a.vel.x *= d;
						a.vel.y *= -d;
					}
				}
				// Otherwise spawn it in a random position in a 32
				// radius around it:
				else 
				{	
					let spawnpos = ToM_UtilsP.FindRandomPosAround(pos, 128, mindist: 32);
					SpawnInvPickup(spawnpos,tospawn2);
				}
			}
		}
		stop;
	}
}

class ToM_AmmoSpawner_RedYellow : ToM_EquipmentSpawner 
{
	Default 
	{
		ToM_EquipmentSpawner.weapon1 "ToM_Cards";
		ToM_EquipmentSpawner.weapon2 "ToM_Jacks";
		ToM_EquipmentSpawner.otherPickupChance 25;
	}
}

class ToM_AmmoSpawner_RedYellow_Big : ToM_AmmoSpawner_RedYellow 
{
	Default 
	{
		ToM_EquipmentSpawner.twoPickupsChance 40;
		ToM_EquipmentSpawner.bigPickupChance 100;
	}
}

class ToM_AmmoSpawner_RedYellow_BigOther : ToM_AmmoSpawner_RedYellow 
{
	Default 
	{
		ToM_EquipmentSpawner.twoPickupsChance 40;
		ToM_EquipmentSpawner.bigPickupChance 100;
		ToM_EquipmentSpawner.otherPickupChance 50;
	}
}