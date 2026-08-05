#!/usr/bin/env python3
"""
Ghost Monitor - Automated Discord Server Setup Script
This script uses discord.py to connect to a server, create all channels, roles, and post welcome embeds.

Usage:
  pip install discord.py
  python3 setup_discord_server.py --token YOUR_BOT_TOKEN
"""

import sys
import asyncio
import argparse

try:
    import discord
    from discord.ext import commands
except ImportError:
    print("Error: discord.py is not installed. Please run: pip install discord.py")
    sys.exit(1)

parser = argparse.ArgumentParser(description="Setup Ghost Monitor Discord Server")
parser.add_argument("--token", required=True, help="Discord Bot Token")
args = parser.parse_args()

intents = discord.Intents.default()
intents.guilds = True
intents.messages = True
intents.message_content = True

bot = commands.Bot(command_prefix="!", intents=intents)

@bot.event
async def on_ready():
    print(f"Logged in as {bot.user.name} ({bot.user.id})")
    
    for guild in bot.guilds:
        print(f"Configuring Server: {guild.name} (ID: {guild.id})")
        
        # 1. Create Roles
        pro_role = discord.utils.get(guild.roles, name="Pro Backer")
        if not pro_role:
            pro_role = await guild.create_role(name="Pro Backer", color=discord.Color.gold(), hoist=True)
            print("Created role: Pro Backer")
            
        dev_role = discord.utils.get(guild.roles, name="Core Developer")
        if not dev_role:
            dev_role = await guild.create_role(name="Core Developer", color=discord.Color.purple(), hoist=True)
            print("Created role: Core Developer")
            
        member_role = discord.utils.get(guild.roles, name="Community Member")
        if not member_role:
            member_role = await guild.create_role(name="Community Member", color=discord.Color.blue(), hoist=True)
            print("Created role: Community Member")
            
        # 2. Category 1: ANNOUNCEMENTS
        cat_announcements = await guild.create_category("📢 ANNOUNCEMENTS")
        ch_welcome = await cat_announcements.create_text_channel("welcome-and-rules")
        ch_updates = await cat_announcements.create_text_channel("announcements")
        ch_github = await cat_announcements.create_text_channel("github-feed")
        
        # 3. Category 2: COMMUNITY
        cat_community = await guild.create_category("💬 COMMUNITY")
        ch_general = await cat_community.create_text_channel("general-chat")
        ch_jarvis = await cat_community.create_text_channel("jarvis-prompts")
        ch_setups = await cat_community.create_text_channel("mac-power-setups")
        
        # 4. Category 3: FEEDBACK & SUPPORT
        cat_support = await guild.create_category("🛠️ SUPPORT & FEEDBACK")
        ch_requests = await cat_support.create_text_channel("feature-requests")
        ch_bugs = await cat_support.create_text_channel("bug-reports")
        
        # 5. Category 4: VIP PRO LOUNGE (Restricted to Pro Backer & Core Dev)
        overwrites = {
            guild.default_role: discord.PermissionOverwrite(read_messages=False),
            pro_role: discord.PermissionOverwrite(read_messages=True),
            dev_role: discord.PermissionOverwrite(read_messages=True)
        }
        cat_vip = await guild.create_category("⭐ PRO VIP LOUNGE", overwrites=overwrites)
        ch_vip = await cat_vip.create_text_channel("pro-exclusive-chat")
        
        # Send Welcome Embed to #welcome-and-rules
        embed = discord.Embed(
            title="👻 Welcome to Ghost Monitor Community!",
            description="The official Discord home for **Ghost Monitor** — The Ultimate macOS Swiss Army Knife & JARVIS Voice OS.",
            color=0x00F2FE
        )
        embed.add_field(name="📜 Server Rules", value="1. Be polite and constructive.\n2. No spam or unauthorized promotional links.\n3. Post bug reports in `#bug-reports`.\n4. Feature suggestions go in `#feature-requests`.", inline=False)
        embed.add_field(name="🔗 Official Links", value="• **Website:** http://localhost:3000\n• **GitHub Repo:** https://github.com/anassagd432/GhostMonitor.git\n• **Download DMG:** `GhostMonitor-Installer.dmg`", inline=False)
        embed.set_footer(text="Ghost Monitor v2.4 • Built Native for macOS")
        
        await ch_welcome.send(embed=embed)
        print("Sent Welcome Embed to #welcome-and-rules!")
        
        print("Server Setup Complete! Exiting script.")
        await bot.close()

if __name__ == "__main__":
    try:
        bot.run(args.token)
    except Exception as e:
        print(f"Error running bot: {e}")
