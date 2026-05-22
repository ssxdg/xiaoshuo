# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

This repository contains Chinese long-form novels being written with AI assistance. The primary project is **命星凡尘** (Destiny Star Mortal World), a cultivation/fantasy novel.

## Project Structure

```
命星凡尘/
├── project.md           # Novel settings, character tables, chapter planning
├── foreshadowing.md    # Plot foreshadowing tracking
└── 第1卷_凡尘起航/     # Volume 1 (in progress)
    ├── 第一章_xxx.md   # Chapters 1-15+ (each is a separate file)
    └── ...
```

## Writing Guidelines

When working on novel chapters, use the **ai-novel-creation** skill. Key requirements:

- **Minimum 3000 characters** per chapter (actual count, not estimates)
- Each chapter needs a **蓝图 (blueprint)** with at least 4 scene cards
- **4+ complete scenes** per chapter with clear goals, conflicts, and consequences
- **2+ external events** (attacks, negotiations, trials, discoveries)
- **1+ internal change** (character attitude shift, relationship progress)
- Use the skill's validation script to verify chapter quality

### Validation Command

Use PowerShell to validate chapter word counts:

```powershell
powershell -ExecutionPolicy Bypass -File "skills文件/ai-novel-creation/scripts/validate_chapter.ps1" -Path "命星凡尘/第1卷_凡尘起航/第N章_标题.md"
```

## Current Project State

- **命星凡尘**: 15 chapters completed in Volume 1
- Main character: 林砚尘 (Lin Yanchen) - cultivation protagonist
- Current arc: Breaking through to Foundation Building stage after major tournament

## Key Files

- `project.md` - Contains novel metadata, character tables, completed chapters, current progress
- `foreshadowing.md` - Tracks plot threads and their status (plant/advance/resolve)

## Permissions

This project permits PowerShell execution for chapter validation via the ai-novel-creation skill.