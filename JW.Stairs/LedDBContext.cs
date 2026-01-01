using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class Scene
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }
    public required string Name { get; set; }
    public List<Frame> Frames { get; set; } = [];
}

public class Frame
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }
    public int OrderNr { get; set; }
    public int SceneId { get; set; }
    public int WaitTillNextFrame { get; set; }
    public Scene Scene { get; set; } = null!;
    public List<Led> Leds { get; set; } = [];
}

public class Led
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }
    public int FrameId { get; set; }
    public int LedNr { get; set; }
    public int ColorRed { get; set; }
    public int ColorGreen { get; set; }
    public int ColorBlue { get; set; }
    public int ColorAlpha { get; set; }
    public Frame Frame { get; set; } = null!;
}

public class LedDbContext : DbContext
{
    public DbSet<Scene> Scenes { get; set; }
    public DbSet<Frame> Frames { get; set; }
    public DbSet<Led> Leds { get; set; }

    public LedDbContext()
    {
        Database.EnsureCreated();
    }

    protected override void OnConfiguring(DbContextOptionsBuilder options)
        => options.UseSqlite("Data Source=ledTemp.db");
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Scene>()
            .HasKey(s => s.Id);

        modelBuilder.Entity<Frame>()
            .HasKey(f => f.Id);
        
        modelBuilder.Entity<Frame>()
            .HasIndex(f => new { f.SceneId, f.OrderNr }) // Composite unique index
            .IsUnique();

        modelBuilder.Entity<Led>()
            .HasKey(l => l.Id);
    }
}
