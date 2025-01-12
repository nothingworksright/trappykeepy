﻿using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TrappyKeepy.Domain.Models
{
    /// <summary>
    /// Table to store permit records.
    /// </summary>
    [Table("permits", Schema = "tk")]
    public partial class Permit
    {
        /// <summary>
        /// UUID primary key.
        /// </summary>
        [Key]
        [Column("id")]
        public Guid Id { get; set; }
        /// <summary>
        /// UUID from the tk.keepers table.
        /// </summary>
        [Column("keeper_id")]
        public Guid KeeperId { get; set; }
        /// <summary>
        /// UUID from the tk.users table.
        /// </summary>
        [Column("user_id")]
        public Guid? UserId { get; set; }
        /// <summary>
        /// UUID from the tk.groups table.
        /// </summary>
        [Column("group_id")]
        public Guid? GroupId { get; set; }

        [ForeignKey(nameof(GroupId))]
        [InverseProperty("Permits")]
        public virtual Group? Group { get; set; }
        [ForeignKey(nameof(KeeperId))]
        [InverseProperty("Permits")]
        public virtual Keeper Keeper { get; set; } = null!;
        [ForeignKey(nameof(UserId))]
        [InverseProperty("Permits")]
        public virtual User? User { get; set; }
    }
}
