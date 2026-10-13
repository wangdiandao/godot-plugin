using Godot;

public partial class ExampleResource : Resource
{
    private long _score;
    [Signal] public delegate void ScoreChangedEventHandler(long score);
    [Export]
    public long Score
    {
        get => _score;
        set
        {
            long next = System.Math.Clamp(value, 0L, 100L);
            if (_score == next) return;
            _score = next;
            EmitChanged();
            EmitSignal(SignalName.ScoreChanged, _score);
        }
    }
    public long Add(long delta)
    {
        // Compare before adding: even long inputs can overflow when summed.
        Score = delta >= 100L - _score ? 100L : (delta <= -_score ? 0L : _score + delta);
        return Score;
    }
}
