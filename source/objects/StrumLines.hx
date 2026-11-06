package funkin.game;

import objects.Character;
import objects.StrumNote;
import objects.Note;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.math.FlxPoint;

class StrumLine extends FlxTypedGroup<StrumNote> {
    public var characters:Array<Character> = [];
    public var cpu:Bool = false;
    public var opponentSide:Bool = false;
    public var startingPos:FlxPoint;
    public var strumScale:Float = 1;
    
    // Sistema do Codename trazido para cá:
    public var notes:FlxTypedGroup<Note>; // Use NoteGroup se tiver adaptado, se não, FlxTypedGroup<Note>
    public var vocals:FlxSound;

    public function new(characters:Array<Character>, startingPos:FlxPoint, strumScale:Float = 1, cpu:Bool = false, opponentSide:Bool = true, ?vocalPrefix:String = "") {
        super();
        this.characters = characters;
        this.startingPos = startingPos;
        this.strumScale = strumScale;
        this.cpu = cpu;
        this.opponentSide = opponentSide;
        
        this.notes = new FlxTypedGroup<Note>(); // Ou new NoteGroup();

        // Adaptação dos Vocais Individuais do Codename usando o sistema do Psych/Flixel:
        if (vocalPrefix != "" && backend.Mods.currentModDirectory != null) {
            // No Psych, os arquivos de voz são carregados de forma ligeiramente diferente do Codename
            var voiceKey:String = backend.Paths.voices(states.PlayState.SONG.song) + "-" + vocalPrefix;
            vocals = new FlxSound().loadEmbedded(voiceKey);
            flixel.FlxG.sound.list.add(vocals);
        } else {
            vocals = new FlxSound();
        }
        vocals.persist = false;
    }

    public override function update(elapsed:Float) {
        super.update(elapsed);
        if (notes != null) notes.update(elapsed);
    }

    public override function draw() {
        super.draw();
        if (notes != null) {
            notes.cameras = cameras;
            notes.draw();
        }
    }
}
