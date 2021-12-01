﻿using System.ComponentModel.DataAnnotations;

namespace TrappyKeepy.Domain.Models
{
    public class UserDto
    {
        public Guid? Id { get; set; }
        [StringLength(50)]
        public string? Name { get; set; }
        public string? Password { get; set; }
        public string? Email { get; set; }
        public string? Role { get; set; }
        public DateTime? DateCreated { get; set; }
        public DateTime? DateActivated { get; set; }
        public DateTime? DateLastLogin { get; set; }
    }

    public class UserSessionDto
    {
        public string? Email { get; set; }
        public string? Password { get; set; }
    }
}