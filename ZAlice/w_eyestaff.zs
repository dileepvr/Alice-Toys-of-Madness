class ToM_Eyestaff : ToM_BaseWeapon
{
	int charge;
	private ToM_LaserBeam beam1;	
	private ToM_LaserBeam beam2;	
	
	const ES_FULLCHARGE = 42;
	const ES_FULLALTCHARGE = 40;
	const ES_PARTALTCHARGE = 8;
	int altStartupFrame;
	
	int altCharge;
	vector2 altChargeOfs;
	ToM_ESAimingCircle aimCircle;
	vector3 aimCirclePos;
	
	Default
	{
		Tag "Jabbberwock's Eye Staff";
		Weapon.slotnumber 6;
		weapon.ammotype1 "ToM_PurpleMana";
		weapon.ammouse1 1;
		weapon.ammogive1 100;
		weapon.ammotype2 "ToM_PurpleMana";
		weapon.ammouse2 2;
	}
	
	action void A_StopCharge()
	{
		A_StopSound(CHAN_WEAPON);
		invoker.charge = 0;
		invoker.altCharge = 0;
		invoker.aimCircle = null;
	}
	
	action void A_FireBeam()
	{
		if (!self || !self.player)
			return;
		if (!invoker.beam1)
		{
			invoker.beam1 = ToM_LaserBeam.Create(self, 10, 4.2, -1.4, type: "ToM_EyestaffBeam1");
		}
		if (!invoker.beam2)
		{
			invoker.beam2 = ToM_LaserBeam.Create(self, 10, 4.2, -1.25, type: "ToM_EyestaffBeam2");
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
	
	action void A_EyestaffFlash(StateLabel label, double alpha = 0)
	{
		A_Overlay(PSP_Flash, label);
		A_OverlayFlags(PSP_Flash, PSPF_Renderstyle|PSPF_ForceAlpha, true);
		A_OverlayRenderstyle(PSP_Flash, Style_Add);
		if (alpha <= 0)
		{
			alpha = ToM_UtilsP.LinearMap(invoker.charge, 0, ES_FULLCHARGE, 0.0, 1.0);
		}
		A_OverlayAlpha(PSP_Flash, alpha);
	}
	
	action void A_EyestaffRecoil()
	{
		//A_DampedRandomOffset(3,3, 2);
		A_OverlayPivot(OverlayID(),0, 0);
		A_OverlayPivot(PSP_Flash, 0, 0);
		double sc = frandom[eye](0, 0.025);
		A_OverlayScale(OverlayID(), 1 + sc, 1 + sc, WOF_INTERPOLATE);
		A_OverlayScale(PSP_Flash, 1 + sc, 1 + sc, WOF_INTERPOLATE);
		A_AttackZoom(0.001, 0.05, 0.002);
	}
	
	action state A_DoAltCharge()
	{
		invoker.charge++;
		if (tom_debugmessages)
		{
			console.printf("Eyestaff alt charge: %d", invoker.charge);
		}
		
		// Cancel charge if:
		// 1. we're out of ammo
		// 2. we reached maximum charge
		// 3. we reached at least partial charge and
		// the player is not holding the attack button
		if (!invoker.DepleteAmmo(invoker.bAltFire, true) || invoker.charge >= ES_FULLALTCHARGE || (!PressingAttackButton() && invoker.charge >= ES_PARTALTCHARGE))
		{
			return ResolveState("AltFireDo");
		}
		
		A_WeaponOffset(
			invoker.altChargeOfs.x + frandom[eye](-1,1), 
			invoker.altChargeOfs.y + frandom[eye](-1,1), 
			WOF_INTERPOLATE
		);
		return ResolveState(null);
	}
	
	action void A_AimCircle(double dist = 350)
	{
		if (!invoker.aimCircle)
			invoker.aimCircle = ToM_ESAimingCircle(Spawn("ToM_ESAimingCircle", pos));
		
		double atkheight = ToM_UtilsP.GetPlayerAtkHeight(PlayerPawn(self));
		
		FLineTraceData tr;
		bool traced = LineTrace(angle, dist, pitch, TRF_THRUACTORS, atkheight, data: tr);
		
		vector3 ppos;
		if (tr.HitType == Trace_HitNone)
		{
			let dir = (cos(angle)*cos(pitch), sin(angle)*cos(pitch), sin(-pitch));
			ppos = (pos + (0,0,atkheight)) + (dir * dist);
		}
		else
		{
			ppos = tr.HitLocation;
		}
		
		ppos.z = level.PointInSector(ppos.xy).NextLowestFloorAt(ppos.x, ppos.y, ppos.z);

		invoker.aimCircle.SetOrigin(ppos, true);
	}
	
	action void A_RemoveAimCircle()
	{
		if (invoker.aimCircle)
			invoker.aimCircle.Destroy();
	}
	
	action void A_LaunchSkyMissiles()
	{
		A_WeaponOffset(
			invoker.altChargeOfs.x + frandom[eye](-1.2,1.2), 
			invoker.altChargeOfs.y + frandom[eye](-1.2,1.2), 
			WOF_INTERPOLATE
		);
		
		double ofs = 80;
		let ppos = pos + (frandom[eyemis](-ofs,ofs), frandom[eyemis](-ofs,ofs), floorz);
		ppos.z = level.PointInSector(ppos.xy).NextLowestFloorAt(ppos.x, ppos.y, ppos.z) + 18;
		
		let proj = ToM_EyestaffProjectile(Spawn("ToM_EyestaffProjectile", ppos));
		//ToM_EyestaffProjectile(A_Fire3DProjectile("ToM_EyestaffProjectile", useammo: false, forward: 56 + frandom(-5,5), leftright: frandom(-5,5), updown: 5));
		if (proj)
		{
			proj.alt = true;
			proj.target = self;
			proj.A_StartSound("weapons/eyestaff/boom2");
			proj.vel.z = proj.speed;
			proj.vel.xy = (frandom[skyeye](-3,3), frandom[skyeye](-3,3));
		}
	}
	
	action void A_SpawnSkyMissiles(double height = 800)
	{
		if (!invoker.aimCircle)
			return;
		
		double pz = Clamp(invoker.aimCircle.pos.z + height, invoker.aimCircle.pos.z, invoker.aimCircle.ceilingz);
		
		let ppos = (invoker.aimCircle.pos.x, invoker.aimCircle.pos.y, pz);
		
		let sms = ToM_SkyMissilesSpawner(Spawn("ToM_SkyMissilesSpawner", ppos));
		if (sms)
		{
			sms.charge = invoker.altCharge;
			sms.target = self;
			sms.tracer = invoker.aimCircle;
		}
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
			A_RemoveAimCircle();
		}
	}

	States
	{
	Spawn:
		ALJE A -1;
		stop;
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
		JEYC A 1 
		{
			A_ResetZoom();
			A_WeaponReady();
		}
		wait;
	Fire:
		JEYC A 1
		{
			A_EyestaffFlash("BeamFlash");
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
			A_EyestaffFlash("BeamFlash", frandom[eye](0.3, 1));
			A_StartSound("weapons/eyestaff/beam", CHAN_WEAPON, CHANF_LOOPING);
			A_EyestaffRecoil();
			A_FireBeam();
			A_FireBullets(0, 0, 1, 5, pufftype: "ToM_EyestaffPuff", flags:FBF_NORANDOM|FBF_USEAMMO);
		}
		TNT1 A 0 
		{
			if (PressingAttackButton() && A_CheckAmmo())
				return ResolveState("FireBeam");
			return ResolveState(null);
		}
		goto FireEnd;
	BeamFlash:
		JEYC F 2 bright;
		stop;
	FireEnd:
		TNT1 A 0 
		{
			A_StopBeam();
			A_StopSound(CHAN_WEAPON);
			let proj = A_FireProjectile("ToM_EyestaffProjectile", useammo: false);
			if (proj)
				proj.A_StartSound("weapons/eyestaff/fireProjectile");
		}
		JEYC ACE 1 A_AttackZoom(0.03, 0.1);
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
		TNT1 A 0 A_CheckReload();
		TNT1 A 0 A_ResetPsprite(OverlayID(), 9);
		JEYC EEDDCCBBA 1;
		goto ready;
	AltFlash:
		JEYC G 10 bright;
		stop;
	AltFire:
		//TNT1 A 0 A_OverlayPivot(OverlayID(), 1, 1);
		JEYC AAABBBCCCDDDEEE 1 
		{
			A_WeaponOffset(-5, 1.4, WOF_ADD);
			let psp = player.FindPSprite(OverlayID());
			if (psp)
				invoker.altStartupFrame = psp.frame;
			invoker.altChargeOfs = (psp.x, psp.y);
			//A_ScalePSprite(OverlayID(), -0.01, -0.01, WOF_ADD);
			if (!PressingAttackButton())
			{
				A_RemoveAimCircle();
				return ResolveState("AltFireEndFast");
			}
			return ResolveState(null);
		}
	AltCharge:
		JEYC EE 1
		{
			A_StartSound("weapons/eyestaff/charge2", CHAN_WEAPON, CHANF_LOOPING);
			A_AimCircle(400);
			A_EyestaffFlash("AltFlash");
			A_SpawnPSParticle("ChargeParticle", bottom: true, density: 4, xofs: 120, yofs: 120);
		}			
		JEYC E 1 { return A_DoAltCharge(); }
		loop;
	AltFireDo:
		JEYC E 6;
		TNT1 A 0 A_StopSound(CHAN_WEAPON);
		JEYC E 2
		{
			invoker.charge--;
			invoker.altCharge++;
			A_EyestaffFlash("AltFlash");
			if (invoker.charge <= 0)
				return ResolveState("AltFireEnd");
			
			A_LaunchSkyMissiles();			
			return ResolveState(null);
		}
		wait;
	AltFireEnd:
		JEYC E 15
		{
			A_SpawnSkyMissiles();
			A_StopCharge();
			A_ClearOverlays(PSP_Flash,PSP_Flash);
		}
	AltFireEndFast:
		JEYC # 0 
		{
			let psp = player.FindPSprite(OverlayID());
			psp.frame = invoker.altStartupFrame;
			A_ResetPsprite(OverlayID(), invoker.altStartupFrame * 2);
		}
		JEYC # 2
		{
			let psp = player.FindPSprite(OverlayID());
			if (psp.frame <= 0)
				return ResolveState("Ready");
			
			psp.frame--;
			return ResolveState(null);
		}
		wait;
	ChargeParticle:
		JEYC P 0 
		{
			A_OverlayPivotAlign(OverlayID(),PSPA_CENTER,PSPA_CENTER);
			A_OverlayFlags(OverlayID(),PSPF_RENDERSTYLE|PSPF_FORCEALPHA,true);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayAlpha(OverlayID(),0);
			A_OverlayScale(OverlayID(),0.5,0.5);
			if (invoker.bAltFire)
			{
				let psp = player.FindPSprite(OverlayID());
				psp.frame++;
			}
		}
		#### ############## 1 bright 
		{
			double scalestep = invoker.bAltFire ? 0.1 : 0.05;
			A_OverlayScale(OverlayID(),scalestep,scalestep,WOF_ADD);
			let psp = player.FindPSprite(OverlayID());
			if (psp) 
			{
				double alpahstep = invoker.bAltFire ? 0.075 : 0.05;
				psp.alpha = Clamp(psp.alpha + alpahstep, 0, 0.85);
				A_OverlayOffset(OverlayID(),psp.x * 0.85, psp.y * 0.85, WOF_INTERPOLATE);
			}
		}
		stop;
	}
}

class ToM_EyestaffPuff : ToM_BasePuff
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

class ToM_EyestaffProjectile : ToM_Projectile
{
	bool alt;
	const TRAILOFS = 6;
	
	static const color SmokeColors[] =
	{
		"850464",
		"d923aa",
		"f74fcc"
	};

	Default
	{
		ToM_Projectile.flarecolor "ff38f5";
		+FORCEXYBILLBOARD
		+NOGRAVITY
		+FORCERADIUSDMG
		+BRIGHT
		+ROLLCENTER
		deathsound "weapons/eyestaff/boom1";
		height 13;
		radius 10;
		speed 22;		
		damage (40);
		Renderstyle 'Add';
		alpha 0.5;
		xscale 5;
		yscale 6;
	}		
	
	override void PostBeginPlay()
	{
		super.PostBeginPlay();
		A_FaceMovementDirection();
		if (alt)
		{
			bNOINTERACTION = true;
			double vx = 3.5;
			int life = 25;
			int parts = 12;
			double pangle = 360. / parts;
			for (int i = 0; i < parts; i++)
			{
				int r = random[eyec](0, ToM_EyestaffProjectile.SmokeColors.Size() - 1);
				let col = ToM_EyestaffProjectile.SmokeColors[r];
				A_SpawnParticle(
					col,
					SPF_FULLBRIGHT|SPF_RELATIVE,
					lifetime: life,
					size: 7,
					angle: pangle * i,
					velx: vx,
					accelx: -(vx / life),
					accelz: -0.1,
					sizestep: 1. / life
				);
			}
		}
	}
	
	override void Tick()
	{
		super.Tick();
		if (isFrozen())
			return;
		if (alt)
			A_FadeOut(0.07);
		roll += 11;
		vector3 projpos = ToM_UtilsP.GetRelativePosition(self, (-TRAILOFS, -TRAILOFS, 0));
		Spawn("ToM_EStrail", projpos);
		projpos = ToM_UtilsP.GetRelativePosition(self, (-TRAILOFS, TRAILOFS, 0));
		Spawn("ToM_EStrail", projpos);
	}
	
	States
	{
	Spawn:
		AMRK A 1 
		{
			double svel = 2;
			let smk = ToM_WhiteSmoke.Spawn(
				pos,
				ofs: 4,
				vel: (
					frandom[essmk](-svel,svel),
					frandom[essmk](-svel,svel),
					frandom[essmk](-svel,svel)
				),
				scale: 0.1,
				alpha: 0.3,
				fade: 0.15,
				dbrake: 0.6
			);
			if (smk)
			{
				smk.A_SetRenderstyle(smk.alpha, Style_Shaded);
				smk.SetShade(SmokeColors[random[essmk](0, SmokeColors.Size() - 1)]);
				smk.bBRIGHT = true;
			}
		}
		loop;
	Death:
		TNT1 A 1 
		{
			A_Explode(80, 128);
			let s = ToM_SphereFX.Spawn(pos, size: 48, alpha: 0.6, grow: 1.15, fade: 0.05);
			if (s)
			{
				s.SetShade(flarecolor);
				s.bBRIGHT = true;
			}
			let s2 = ToM_SphereFX.Spawn(pos, size: 16, alpha: 0.8, grow: 1.15, fade: 0.05);
			if (s2)
			{
				s2.SetShade("fcb126");
				s2.bBRIGHT = true;
			}
			double svel = 4;
			for (int i = 8; i > 0; i--)
			{
				let smk = ToM_WhiteSmoke.Spawn(
					pos,
					ofs: 16,
					vel: (
						frandom[essmk](-svel,svel),
						frandom[essmk](-svel,svel),
						frandom[essmk](-svel,svel)
					),
					scale: 0.4,
					rotation: 2,
					fade: 0.1,
					dbrake: 0.7,
					dscale: 1.015
				);
				if (smk)
				{
					smk.A_SetRenderstyle(smk.alpha, Style_Shaded);
					smk.SetShade(SmokeColors[random[essmk](0, SmokeColors.Size() - 1)]);
					smk.bBRIGHT = true;
				}
			}
		}
		//BAL2 CDE 5;
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
		scale 0.08;
	}	
}

class ToM_AimingTracer : LineTracer
{
	override ETraceStatus TraceCallback()
    {
		if (results.hitType == TRACE_HitWall || results.hitType == TRACE_HitCeiling || results.hitType == TRACE_HitFloor)
			return TRACE_Stop;
        
		return TRACE_Skip;
	}
}

class ToM_ESAimingCircle : ToM_BaseActor
{
	Default
	{
		+NOBLOCKMAP
		+NOINTERACTION
		+BRIGHT
		renderstyle 'Translucent';
		alpha 0.42;
		radius 256;
		scale 256;
		height 1;
	}
	
	States 
	{
	Spawn:
		AMRK A 1 
		{
			A_SetAngle(angle+0.5, SPF_INTERPOLATE);
			SetZ(floorz+1);
		}
		loop;
	}
}

class ToM_SkyMissilesSpawner : ToM_BaseActor
{
	int charge;
	double zShift;
	double circleRad;
	
	static const color EyeColor[] = 
	{
		"c334eb",
		"ff00f7",
		"ffe8fe",
		"70006b"
	};
	
	Default
	{
		+NOINTERACTION
		+NOBLOCKMAP
		radius 160;
		height 1;
	}
	
	override void PostBeginPlay()
	{
		super.PostBeginPlay();
		let proj = GetDefaultByType("ToM_EyestaffProjectile");
		if (proj)
		{
			zShift = proj.height;
		}
		let circle = GetDefaultByType("ToM_ESAimingCircle");
		if (circle)
		{
			circleRad = circle.radius;
		}
	}
	
	override void Tick()
	{
		if (!target)
		{
			Destroy();
			return;
		}
		super.Tick();
		
		if (isFrozen())
			return;
			
		for (int i = 6; i > 0; i--)
		{		
			vector3 ppos = pos;
			
			ppos.xy = Vec2Angle(frandom[eye](0, circleRad), random[eye](0, 359));
			
			double toplimit = level.PointInSector(ppos.xy).NextHighestCeilingAt(ppos.x, ppos.y, ppos.z, ppos.z, ppos.z+ height);
			
			ppos.z = Clamp(ppos.z, floorz, toplimit);
			
			let t = Spawn("ToM_EStrail", ppos);
			if (t)
				t.scale *= frandom[eyec](1, 3);
		}
	}
	
	States 
	{
	Spawn:
		TNT1 A 60;
		TNT1 A 3 
		{
			if (charge > 0)
			{
				vector3 ppos = pos;
				for (int i = 10; i > 0; i--)
				{
					ppos = (
						pos.x + frandom(-radius, radius), 
						pos.y + frandom(-radius, radius), 
						pos.z - zShift
					);
					double botlimit = level.PointInSector(ppos.xy).NextLowestFloorAt(ppos.x, ppos.y, ppos.z);
					double toplimit = level.PointInSector(ppos.xy).NextHighestCeilingAt(ppos.x, ppos.y, ppos.z, ppos.z, ppos.z + 1);
					ppos.z = Clamp(ppos.z, botlimit, toplimit - zShift);
					if (Level.IsPointInLevel(ppos))
						break;
				}
				let proj = Spawn("ToM_EyestaffProjectile", ppos);
				if (proj)
				{
					proj.target = target;
					proj.vel.z = -proj.speed;
					double hvel = 2.8;
					proj.vel.xy = (frandom(-hvel,hvel), frandom(-hvel,hvel));
					proj.A_FaceMovementDirection();
					proj.A_StartSound("weapons/eyestaff/boom2");
				}
				charge--;
			}
			else
			{
				if (tracer)
				{
					tracer.A_FadeOut(0.05);
				}
				if (!tracer)
				{
					Destroy();
				}
			}
		}
		wait;
	}
}