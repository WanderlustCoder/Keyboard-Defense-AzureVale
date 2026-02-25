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

    /// <summary>
    /// Gets the number of pooled objects currently checked out and considered active.
    /// </summary>
    public int ActiveCount => _totalCreated - _available.Count;
    /// <summary>
    /// Gets the number of pooled objects currently stored and ready for reuse.
    /// </summary>
    public int AvailableCount => _available.Count;
    /// <summary>
    /// Gets the total number of instances the pool has created since construction.
    /// </summary>
    public int TotalCreated => _totalCreated;

    /// <summary>
    /// Creates an object pool with configurable preallocation and retention limits.
    /// </summary>
    /// <param name="factory">Factory used to create new instances during preallocation and when the pool is exhausted.</param>
    /// <param name="reset">Optional callback invoked before an item is stored back in the pool.</param>
    /// <param name="initialSize">Number of instances created immediately and pushed into the available stack.</param>
    /// <param name="maxSize">Maximum available-item capacity retained for reuse.</param>
    /// <remarks>
    /// Preallocated items increment <see cref="TotalCreated"/> and are immediately reusable by <see cref="Get"/>.
    /// </remarks>
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

    /// <summary>
    /// Gets an instance for use by the caller, preferring a previously returned object when available.
    /// </summary>
    /// <returns>An instance of <typeparamref name="T"/> that is ready for immediate use.</returns>
    /// <remarks>
    /// Retrieval is LIFO from the available stack. When no cached item exists, a new instance is created and
    /// <see cref="TotalCreated"/> is incremented.
    /// </remarks>
    public T Get()
    {
        if (_available.Count > 0)
            return _available.Pop();

        _totalCreated++;
        return _factory();
    }

    /// <summary>
    /// Returns an instance to the pool so it can be reused by future <see cref="Get"/> calls.
    /// </summary>
    /// <param name="item">Instance to return to the pool.</param>
    /// <remarks>
    /// The optional reset callback is invoked before capacity is checked. If available capacity is already at
    /// <c>maxSize</c>, the item is discarded rather than retained.
    /// </remarks>
    public void Return(T item)
    {
        _reset?.Invoke(item);
        if (_available.Count < _maxSize)
            _available.Push(item);
    }
}
