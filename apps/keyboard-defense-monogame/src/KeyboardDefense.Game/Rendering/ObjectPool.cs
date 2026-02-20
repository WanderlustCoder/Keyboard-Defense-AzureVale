using System;
using System.Collections.Generic;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Generic object pool to reduce GC pressure for particles, damage numbers, etc.
/// Ported from game/object_pool.gd.
/// </summary>
public class ObjectPool<T> where T : class
{
    private readonly Stack<T> _available;
    private readonly Func<T> _factory;
    private readonly Action<T>? _reset;
    private readonly int _maxSize;
    private int _totalCreated;

    public int ActiveCount => _totalCreated - _available.Count;
    public int AvailableCount => _available.Count;
    public int TotalCreated => _totalCreated;

    public ObjectPool(Func<T> factory, Action<T>? reset = null, int initialSize = 32, int maxSize = 256)
    {
        _factory = factory;
        _reset = reset;
        _maxSize = maxSize;
        _available = new Stack<T>(initialSize);

        for (int i = 0; i < initialSize; i++)
        {
            _available.Push(_factory());
            _totalCreated++;
        }
    }

    public T Get()
    {
        if (_available.Count > 0)
            return _available.Pop();

        _totalCreated++;
        return _factory();
    }

    public void Return(T item)
    {
        _reset?.Invoke(item);
        if (_available.Count < _maxSize)
            _available.Push(item);
    }
}
