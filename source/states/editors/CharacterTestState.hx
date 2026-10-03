package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUICheckBox;
import flixel.group.FlxGroup.FlxTypedGroup;
import backend.Song;
import backend.Conductor;
import objects.Character;
import objects.StrumNote;

class CharacterTestState extends backend.MusicBeatState
{
    var character:Character;
    var UI_box:FlxUITabMenu;
    
    // Inputs da UI
    var characterInput:FlxUIInputText;
    var songInput:FlxUIInputText;
    var playAsPlayerCheckbox:FlxUICheckBox;
    
    var strumLines:FlxTypedGroup<StrumNote>;
    var filteredNotes:Array<Dynamic> = [];
    var playAsPlayer:Bool = false;

    override function create()
    {
        super.create();
        FlxG.mouse.visible = true;

        // 1. Carrega o fundo padrão (Stage da Week 1)
        var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(backend.Paths.image('stageback'));
        bg.scrollFactor.set(0.9, 0.9);
        add(bg);

        var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(backend.Paths.image('stagefront'));
        stageFront.scrollFactor.set(0.9, 0.9);
        add(stageFront);

        // 2. Cria o Personagem de Teste (Padrão: BF)
        character = new Character(400, 130, 'bf', true);
        add(character);

        // 3. Cria as Strums (Setas estáticas na HUD)
        strumLines = new FlxTypedGroup<StrumNote>();
        add(strumLines);
        for (i in 0...4) {
            var strum:StrumNote = new StrumNote(100 + (i * 110), 50, i, 0);
            strumLines.add(strum);
        }

        // 4. Inicializa o Painel de Abas da UI
        setupUI();
    }

    function setupUI()
    {
        // Define as abas disponíveis
        var tabs = [
            {name: "char", label: 'Character'},
            {name: "song", label: 'Song & Chart'}
        ];

        UI_box = new FlxUITabMenu(null, tabs, true);
        UI_box.resize(300, 400);
        UI_box.x = FlxG.width - UI_box.width - 20;
        UI_box.y = 20;
        UI_box.scrollFactor.set();
        add(UI_box);

        addCharacterUI();
        addSongUI();
    }

    function addCharacterUI()
    {
        var tab_char = new FlxUI(null, UI_box);
        tab_char.name = "char";

        // Input para o nome do JSON do Personagem
        characterInput = new FlxUIInputText(10, 30, 150, 'bf', 8);
        
        var loadCharBtn = new FlxUIButton(170, 28, "Load Char", function() {
            reloadCharacter(characterInput.text);
        });

        // Checkbox "Play as Player"
        playAsPlayerCheckbox = new FlxUICheckBox(10, 80, null, null, "Play as Player", 100);
        playAsPlayerCheckbox.callback = function() {
            playAsPlayer = playAsPlayerCheckbox.checked;
        };

        tab_char.add(characterInput);
        tab_char.add(loadCharBtn);
        tab_char.add(playAsPlayerCheckbox);
        UI_box.addGroup(tab_char);
    }

    function addSongUI()
    {
        var tab_song = new FlxUI(null, UI_box);
        tab_song.name = "song";

        // Input para o nome da Música
        songInput = new FlxUIInputText(10, 30, 150, 'bopeebo', 8);

        var loadSongBtn = new FlxUIButton(170, 28, "Load & Test", function() {
            startChartTest(songInput.text);
        });

        tab_song.add(songInput);
        tab_song.add(loadSongBtn);
        UI_box.addGroup(tab_song);
    }

    function reloadCharacter(charName:String)
    {
        if(character != null) character.destroy();
        
        // Remove do grupo e recria com o novo JSON
        remove(character);
        character = new Character(400, 130, charName, !playAsPlayer);
        add(character);
    }

    function startChartTest(songName:String)
    {
        filteredNotes = [];
        
        // Carrega o áudio Instrumental e Vozes
        FlxG.sound.playMusic(backend.Paths.inst(songName), 1, false);
        
        // Se a música tiver arquivo de vozes próprio, carrega também
        if(backend.Paths.voices(songName) != null) {
            // Lógica para sincronizar o FlxSound das vozes com o Inst se necessário
        }

        // Executa a sua filtragem de Notas inteligente que discutimos antes
        try {
            var fullChart = Song.loadFromJson(songName.toLowerCase(), songName.toLowerCase());
            for (section in fullChart.notes) {
                for (noteData in section.sectionNotes) {
                    var isPlayerNote = (noteData[1] > 3);
                    if (section.mustHitSection) isPlayerNote = !isPlayerNote;

                    if ((playAsPlayer && isPlayerNote) || (!playAsPlayer && !isPlayerNote)) {
                        filteredNotes.push(noteData); // Guarda [tempo, direção, sustain]
                    }
                }
            }
            // Ordena as notas por tempo para o loop do update funcionar perfeitamente
            filteredNotes.sort(function(a, b) return Std.int(a[0] - b[0]));
        } catch(e:Dynamic) {
            trace("Erro ao carregar o chart: " + e);
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        // Só processa as notas se a música estiver tocando
        if (FlxG.sound.music != null && FlxG.sound.music.playing)
        {
            Conductor.songPosition = FlxG.sound.music.time;

            while (filteredNotes.length > 0 && filteredNotes[0][0] <= Conductor.songPosition)
            {
                var currentNote = filteredNotes.shift();
                var direction:Int = Std.int(currentNote[1]) % 4;

                // Força o bot ou player a fazer a animação de Sing
                character.playAnim(character.singAnimations[direction], true);
                character.holdTimer = 0;

                // Seta acende no Confirm
                strumLines.members[direction].playAnim('confirm', true);
                strumLines.members[direction].resetAnim = 0.15; // Desliga o brilho após 0.15s
            }
        }
    }
}
