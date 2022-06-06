class ToM_Eyestaff : ToM_BaseWeapon
{
	int charge;
	private ToM_LaserBeam beam1;	
	private ToM_LaserBeam beam2;	
	
	const ES_FULLCHARGE = 42;
	
	Default
	{
		Weapon.slotnumber 6;
		Tag "Jabbberwock's Eye Staff";
	}
	
	action void A_StopCharge()
	{
		invoker.charge = 0;
		A_StopSound(CHAN_WEAPON);
		A_ResetPsprite();
	}
	
	action void A_FireBeam()
	{
		if (!self || !self.player)
			return;
		if (!invoker.beam1)
		{
			invoker.beam1 = ToM_LaserBeam.Create(self, 7, 3.2, -2.3, type: "ToM_EyestaffBeam1");
		}
		if (!invoker.beam2)
		{
			invoker.beam2 = ToM_LaserBeam.Create(self, 7, 3.2, -2.1, type: "ToM_EyestaffBeam2");
		}
		if (invoker.beam1)
		{
			invoker.beam1.SetEnabled(true);
		}
		if (invoker.beam2)
		{
			invoker.beam2.SetEnabled(true);
		}
	}
	
	action void A_StopBeam()
	{
		if (invoker.beam1)
		{
			invoker.beam1.SetEnabled(false);
		}
		if (invoker.beam2)
		{
			invoker.beam2.SetEnabled(false);
		}
	}
	
	action void A_EyeStaffFlash()
	{
		A_Overlay(PSP_Flash, "BeamFlash");
		A_OverlayFlags(PSP_Flash, PSPF_Renderstyle|PSPF_ForceAlpha, true);
		A_OverlayRenderstyle(PSP_Flash, Style_Add);
		A_OverlayAlpha(PSP_Flash, frandom[eye](0.3, 1));
	}
	
	override void DoEffect()
	{
		super.DoEffect();
		if (!owner || !owner.player)
			return;
		let weap = owner.player.readyweapon;
		if (owner.health <= 0 || !weap || weap != self)
		{
			if (beam1) beam1.SetEnabled(false);
			if (beam2) beam2.SetEnabled(false);
		}
	}

	States
	{
	Select:
		JEYC A 0 
		{
			A_WeaponOffset(-24, 90+WEAPONTOP);
			A_OverlayPivot(OverlayID(), 0.6, 0.8);
			A_OverlayRotate(OverlayID(), 30);
		}
		#### ###### 1
		{
			A_WeaponOffset(4, -15, WOF_ADD);
			A_OverlayRotate(OverlayID(), -5, WOF_ADD);
			A_WeaponReady(WRF_NOFIRE|WRF_NOBOB);
		}
		goto Ready;
	Deselect:
		JEYC A 0
		{
			A_OverlayPivot(OverlayID(), 0.6, 0.8);
			A_StopSound(CHAN_WEAPON);
		}
		#### ###### 1
		{
			A_ResetZoom();
			A_WeaponOffset(-4, 15, WOF_ADD);
			A_OverlayRotate(OverlayID(), 5, WOF_ADD);
		}
		TNT1 A 0 A_Lower;
		wait;
	Ready:
		TNT1 A 0 A_ResetPsprite;
		JEYC A 1 
		{
			A_ResetZoom();
			A_WeaponReady();
		}
		wait;
	Fire:
		JEYC A 1
		{
			A_Overlay(PSP_Flash, "BeamFlash");
			A_OverlayFlags(PSP_Flash, PSPF_Renderstyle|PSPF_ForceAlpha, true);
			A_OverlayRenderstyle(PSP_Flash, Style_Add);
			A_OverlayAlpha(PSP_Flash, invoker.LinearMap(invoker.charge, 0, ES_FULLCHARGE, 0.0, 1.0));
		}
		TNT1 A 0
		{
			A_StartSound("weapons/eyestaff/charge1", CHAN_WEAPON, CHANF_LOOPING);
			if (invoker.charge >= ES_FULLCHARGE)
			{
				A_StopCharge();
				return ResolveState("FireBeam");
			}
			if (PressingAttackButton(holdCheck:PAB_HELD))
			{
				A_SpawnPSParticle("ChargeParticle", bottom: true, density: 4, xofs: 120, yofs: 120);
				invoker.charge++;
				//A_DampedRandomOffset(2, 2, 1.2);
				A_AttackZoom(0.001, 0.08, 0.002);
				return ResolveState("Fire");
			}
			A_StopCharge();
			A_StartSound("weapons/eyestaff/chargeoff", CHAN_WEAPON);
			return ResolveState("Ready");
		}
		goto Ready;
	FireBeam:
		JEYC A 2
		{
			A_EyeStaffFlash();
			A_StartSound("weapons/eyestaff/beam", CHAN_WEAPON, CHANF_LOOPING);
			//A_DampedRandomOffset(3,3, 2);
			A_OverlayPivot(OverlayID(),0, 0);
			A_OverlayPivot(PSP_Flash, 0, 0);
			double sc = frandom[eye](0, 0.025);
			A_OverlayScale(OverlayID(), 1 + sc, 1 + sc, WOF_INTERPOLATE);
			A_OverlayScale(PSP_Flash, 1 + sc, 1 + sc, WOF_INTERPOLATE);
			A_AttackZoom(0.001, 0.05, 0.002);
			A_FireBeam();
			A_FireBullets(0, 0, 1, 5, pufftype: "ToM_EyeStaffPuff", flags:FBF_NORANDOM);
		}
		TNT1 A 0 A_ReFire("FireBeam");
		goto FireEnd;
	BeamFlash:
		JEYC F 2 bright;
		stop;
	ChargeParticle:
		JEYC P 0 
		{
			A_OverlayPivotAlign(OverlayID(),PSPA_CENTER,PSPA_CENTER);
			A_OverlayFlags(OverlayID(),PSPF_RENDERSTYLE|PSPF_FORCEALPHA,true);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayAlpha(OverlayID(),0);
			A_OverlayScale(OverlayID(),0.5,0.5);
		}
		#### ############## 1 bright 
		{
			A_OverlayScale(OverlayID(),0.05,0.05,WOF_ADD);
			let psp = player.FindPSprite(OverlayID());
			if (psp) 
			{
				psp.alpha = Clamp(psp.alpha + 0.05, 0, 0.5);
				A_OverlayOffset(OverlayID(),psp.x * 0.85, psp.y * 0.85, WOF_INTERPOLATE);
			}
		}
		stop;
	FireEnd:
		TNT1 A 0 
		{
			A_StopBeam();
			A_StopSound(CHAN_WEAPON);
			let proj = A_FireProjectile("ToM_EyeStaffProjectile");
			if (proj)
				proj.A_StartSound("weapons/eyestaff/fireProjectile");
		}
		JEYC ACE 1;
		JEYC EEEEEE 1 
		{
			A_ResetZoom();
			A_WeaponOffset(frandom[eye](-2, 2), frandom[eye](-2, 2), WOF_ADD);
		}
		JEYC EEEEEE 1
		{
			A_ResetZoom();
			A_WeaponOffset(frandom[eye](-1, 1), frandom[eye](-1, 1), WOF_ADD);
		}
		TNT1 A 0 A_WeaponOffset(0, WEAPONTOP, WOF_INTERPOLATE);
		JEYC EEDDCCBBA 1;
		goto ready;
	}
}

class ToM_EyeStaffPuff : ToM_BasePuff
{
	Default
	{
		+NODAMAGETHRUST
	}
}

class ToM_EyestaffBeam1 : ToM_LaserBeam
{
	double alphadir;
	
	Default
	{
		ToM_LaserBeam.LaserColor "c334eb";
		xscale 3.4;
	}
	
	override void PostBeginPlay()
	{
		super.PostBeginPlay();
		alphadir = -0.05;
	}
	
	override void Tick()
	{
		super.Tick();
		alpha += alphadir;
		if (alpha > 1 || alpha < 0.5)
			alphadir *= -1;
	}
}

class ToM_EyestaffBeam2 : ToM_EyestaffBeam1
{
	Default
	{
		ToM_LaserBeam.LaserColor "ffee00";
		xscale 1.6;
	}
	
	override void PostBeginPlay()
	{
		super.PostBeginPlay();
		alphadir = 0.05;
		alpha = 0.5;
	}
}

class ToM_EyeStaffProjectile : ToM_Projectile
{
	Default
	{
		ToM_Projectile.flarecolor "c334eb";
		+FORCEXYBILLBOARD
		+NOGRAVITY
		+BRIGHT
		deathsound "weapons/eyestaff/boom1";
		translation "0:255=%[0.69,0.00,0.77]:[1.87,0.75,2.00]";
		height 8;
		radius 10;
		speed 22;		
		damage (40);
		Renderstyle 'Add';
		alpha 0.8;
	}		
	
	override void PostBeginPlay()
	{
		super.PostBeginPlay();
		A_FaceMovementDirection();
	}
	
	override void Tick()
	{
		super.Tick();
		if (isFrozen())
			return;
		roll += 8;
		vector3 projpos = GetRelativePosition(self, (0, -16, 0));
		Spawn("ToM_EStrail", projpos);
		projpos = GetRelativePosition(self, (0, 16, 0));
		Spawn("ToM_EStrail", projpos);
	}
	
	States
	{
	Spawn:
		BAL2 AB 4;
		loop;
	Death:
		BAL2 CDE 3;
		stop;
	}
}

class ToM_EStrail : ToM_BaseFlare
{
	Default
	{
		ToM_BaseFlare.fcolor "c334eb";
		ToM_BaseFlare.fadefactor 0.05;
		alpha 1;
		scale 0.06;
	}	
}